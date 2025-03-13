include { FASTP } from '../modules/fastp'
include { BBMAP } from '../modules/bbmap'
include { SAMTOOLS_STATS } from '../modules/samtools'
include { MULTIQC } from '../modules/multiqc'
include { KRAKEN } from '../modules/kraken'

workflow MAIN_WORKFLOW {
    // Define input channels
    ch_input_reads = Channel.fromFilePairs(params.input_pattern, checkIfExists: true)
    ch_ref_dir     = Channel.value(file(params.contaminants_db)) 
    ch_kraken      = Channel.value(file(params.kraken_db))
    
    // Check if contaminants_db exists and is a valid BBMAP database
    Channel.fromPath(params.contaminants_db, checkIfExists: false)
        .ifEmpty { 
            error "ERROR: Contaminants database not found at ${params.contaminants_db}. Please check your contaminants_db path."
        }
    
    Channel.fromPath("${params.contaminants_db}/ref/index", checkIfExists: false)
        .ifEmpty { 
            error "ERROR: BBMAP index not found at ${params.contaminants_db}/ref/index. This does not appear to be a valid BBMAP database."
        }
    
    // Check if kraken_db exists and is a valid Kraken2 database
    Channel.fromPath(params.kraken_db, checkIfExists: false)
        .ifEmpty { 
            error "ERROR: Kraken database not found at ${params.kraken_db}. Please check your kraken_db path."
        }
    
    Channel.fromPath("${params.kraken_db}/hash.k2d", checkIfExists: false)
        .ifEmpty { 
            error "ERROR: hash.k2d file not found at ${params.kraken_db}/hash.k2d. This does not appear to be a valid Kraken2 database."
        }
        
    // Step 1: Run FASTP
    FASTP(ch_input_reads)
    
    // Step 2: Run BBMAP
    FASTP.out.cleaned_reads.view()
    BBMAP(FASTP.out.cleaned_reads, ch_ref_dir)
    
    // Step 3: Run Samtools Stats
    SAMTOOLS_STATS(BBMAP.out.bam)
    BBMAP.out.bam.view()
    
    KRAKEN(BBMAP.out.clean_reads, ch_kraken)
    
    // Step 4: Run MultiQC
    ch_multiqc_input = FASTP.out.json_report.mix(SAMTOOLS_STATS.out.stats).collect()
    MULTIQC(ch_multiqc_input)
}