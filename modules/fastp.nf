process FASTP {
    tag "$sample_id"
    conda "bioconda::fastp=0.23.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0' :
        'biocontainers/fastp:0.23.4--h5f740d0_0' }"
        
    input:
    tuple val(sample_id), path(reads)
    
    output:
    tuple val(sample_id), path("${sample_id}_cleaned_R*.fastq.gz"), emit: cleaned_reads
    path "${sample_id}_fastp.json", emit: json_report
    
    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} \
          --detect_adapter_for_pe -w ${task.cpus} \
          -o ${sample_id}_cleaned_R1.fastq.gz -O ${sample_id}_cleaned_R2.fastq.gz \
          -j ${sample_id}_fastp.json -h ${sample_id}_fastp.html
    """
    
    stub:
    """
    touch ${sample_id}_fastp.json
    touch ${sample_id}_cleaned_R{1,2}.fastq.gz
    """
}