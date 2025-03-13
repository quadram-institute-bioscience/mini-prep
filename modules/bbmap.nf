
process BBMAP {
    tag "$sample_id"
    label 'process_medium'
    conda "bioconda::bbmap=38.93"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/bbmap_samtools_pigz:2a066f0214cc5eb0' :
        'community.wave.seqera.io/library/bbmap_samtools_pigz:79703e935236b43b' }"
        
    input:
    tuple val(sample_id), path(reads)
    path contaminants_db
    
    output:
    tuple val(sample_id), path("${sample_id}_clean_R*.fastq.gz"), emit: clean_reads
    tuple val(sample_id), path("${sample_id}_mapped.bam"), emit: bam
    
    script:
    def avail_mem = task.memory ? (task.memory.toGiga() - 1) : 4
    // Ensure minimum 1GB per CPU
    avail_mem = Math.max(1, avail_mem)
    """
    bbmap.sh -Xmx${avail_mem}g threads=${task.cpus} \
             in1=${reads[0]} in2=${reads[1]} \
             out=${sample_id}_mapped.bam \
             path=${contaminants_db} \
             outu1=${sample_id}_clean_R1.fastq.gz outu2=${sample_id}_clean_R2.fastq.gz
    """
    
    stub:
    """
    touch ${sample_id}_clean_R{1,2}.fastq.gz
    touch ${sample_id}_mapped.bam 
    """
}
