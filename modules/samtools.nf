process SAMTOOLS_STATS {
    tag "$sample_id"
    conda "bioconda::samtools=1.21"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.21--h50ea8bc_0' :
        'biocontainers/samtools:1.21--h50ea8bc_0' }"

    input:
    tuple val(sample_id), path(bam)
    
    output:
    path "${sample_id}.txt", emit: stats
    
    script:
    """
    samtools stats ${bam} > ${sample_id}.txt
    """
}
