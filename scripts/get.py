#!/usr/bin/env python3

import argparse
import os
import requests
import pandas as pd
from tqdm import tqdm
import time
import csv

def parse_arguments():
    parser = argparse.ArgumentParser(description='Download genome FASTA files from NCBI based on accession numbers')
    parser.add_argument('-i', '--input', required=True, help='Input TSV file with accession numbers in first column')
    parser.add_argument('-o', '--outdir', required=True, help='Output directory for downloaded FASTA files')
    parser.add_argument('-c', '--column', default=0, type=int, help='Column index containing accession numbers (default: 0)')
    parser.add_argument('-d', '--delay', default=1, type=float, help='Delay between requests in seconds (default: 1)')
    return parser.parse_args()

def download_genome_fasta(accession, output_dir):
    """Download genome FASTA file from NCBI using the accession number"""
    
    # Format accession to work with NCBI API
    accession = accession.strip()
    
    # Create NCBI API URL for the genome assembly
    base_url = "https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession"
    api_url = f"{base_url}/{accession}/download"
    params = {"include_annotation_type": "GENOME_FASTA", "filename": f"{accession}.zip"}
    
    try:
        # Request the genome data
        response = requests.get(api_url, params=params)
        response.raise_for_status()
        
        # Save the ZIP file
        zip_path = os.path.join(output_dir, f"{accession}.zip")
        with open(zip_path, 'wb') as f:
            f.write(response.content)
        
        # Extract the FASTA file from the ZIP
        import zipfile
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # Find the FASTA file in the ZIP
            fasta_files = [f for f in zip_ref.namelist() if f.endswith('.fna')]
            if fasta_files:
                # Extract the FASTA file and rename it
                zip_ref.extract(fasta_files[0], output_dir)
                os.rename(
                    os.path.join(output_dir, fasta_files[0]),
                    os.path.join(output_dir, f"{accession}.fasta")
                )
        
        # Clean up the ZIP file
        os.remove(zip_path)
        return True
    
    except Exception as e:
        print(f"Error downloading {accession}: {str(e)}")
        return False

def main():
    args = parse_arguments()
    
    # Create output directory if it doesn't exist
    if not os.path.exists(args.outdir):
        os.makedirs(args.outdir)
    
    # Read the TSV file, skipping comment lines
    try:
        # Read all non-comment lines into a list
        data_lines = []
        with open(args.input, 'r') as f:
            for line in f:
                if not line.startswith('#'):
                    data_lines.append(line)
        
        # If no data was found, try reading with comments=None
        if not data_lines:
            print("No non-comment lines found, trying to read with pandas...")
            df = pd.read_csv(args.input, sep='\t', comment='#')
        else:
            # Create a temporary file with just the data lines
            import tempfile
            temp_file = tempfile.NamedTemporaryFile(mode='w+', delete=False)
            try:
                # First write the header line if it exists
                if data_lines and '\t' in data_lines[0]:
                    temp_file.write(data_lines[0])
                # Then write the rest of the data
                for line in data_lines[1:]:
                    temp_file.write(line)
                temp_file.close()
                
                # Read the temporary file with pandas
                df = pd.read_csv(temp_file.name, sep='\t')
            finally:
                # Clean up
                os.unlink(temp_file.name)
        
        # Ensure the column index is valid
        if args.column >= len(df.columns):
            print(f"Warning: Column index {args.column} is out of range. Using first column instead.")
            args.column = 0
            
        accessions = df.iloc[:, args.column].tolist()
        
        # Remove any empty or NaN values
        accessions = [acc for acc in accessions if acc and pd.notna(acc)]
        
    except Exception as e:
        print(f"Error reading input file: {str(e)}")
        print("Trying alternative approach...")
        
        # Fallback to manual reading, skipping comment lines
        try:
            accessions = []
            with open(args.input, 'r') as f:
                for line in f:
                    if not line.startswith('#'):
                        fields = line.strip().split('\t')
                        if fields and len(fields) > args.column:
                            accession = fields[args.column].strip()
                            if accession and accession != "":
                                accessions.append(accession)
        except Exception as e2:
            print(f"Second approach also failed: {str(e2)}")
            return
    
    print(f"Found {len(accessions)} accession numbers to process")
    
    # Download FASTA files for each accession
    successful = 0
    for accession in tqdm(accessions, desc="Downloading genomes"):
        if download_genome_fasta(accession, args.outdir):
            successful += 1
        time.sleep(args.delay)  # Add delay to avoid overwhelming the server
    
    print(f"Download complete. Successfully downloaded {successful} out of {len(accessions)} genomes.")

if __name__ == "__main__":
    main()