# Sort bam files
rule sort:
    input:
        os.path.join(OUTDIR,"mapped/{sample}.bam")
    output:
        os.path.join(OUTDIR,"mapped/{sample}.sort.bam")
    params:
        walltime="864000",
        nodes="1",
        ppn="2",
        prefix=os.path.join(OUTDIR,"mapped/tmp.{sample}")
    resources:
        mem="15GB"
    threads:
        2
    log:
        out_sort = os.path.join(OUTDIR,"log/map/{sample}.sort.log"),
        o = os.path.join(OUTDIR,"log/map/{sample}.sort.o"),
        e = os.path.join(OUTDIR,"log/map/{sample}.sort.e")
       
    conda:
        "envs/samtools.yaml"
    shell:
        "samtools sort {input} -T {params.prefix} --threads 1 -m 3G -o {output} 2> {log.out_sort}"