process KRAKEN {
    tag "$sample_id"
    label 'process_high'
    conda "bioconda::kraken2==2.0.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0' :
        'biocontainers/mulled-v2-8706a1dd73c6cc426e12dd4dd33a5e917b3989ae:c8cbdc8ff4101e6745f8ede6eb5261ef98bdaff4-0' }"
        
    input:
    tuple val(sample_id), path(reads)
    path krakendb
    
    output:
    tuple val(sample_id), path("${sample_id}.kraken.tsv"), emit: report
    
    script:
    """
    kraken2 --db ${krakendb} --paired --report "${sample_id}.kraken.tsv" \
       --threads ${task.cpus} --memory-mapping \
       ${reads[0]} ${reads[1]} 
             
    """

}

 