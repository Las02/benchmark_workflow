# Extract header lengths from a BAM file in order to determine which headers
# to filter from the abundance (i.e. get the mask)
rule get_headers:
    input:
        os.path.join(OUTDIR, "mapped", f"{IDS[1]}.sort.bam")
    output:
        os.path.join(OUTDIR,"abundances/headers.txt")
    params:
        walltime = "86400",
        nodes = "1",
        ppn = "1"
    resources:
        mem = "4GB"
    threads:
        1
    envmodules:
        config['moduleenvs']['samtools']
  
    log:
        head = os.path.join(OUTDIR,"log/abundance/headers.log"),
        o = os.path.join(OUTDIR,"log/abundance/get_headers.o"),
        e = os.path.join(OUTDIR,"log/abundance/get_headers.e")

    shell:
        "samtools view -H {input}"
        " | grep '^@SQ'"
        " | cut -f 2,3"
        " > {output} 2> {log.head} "
 
# Using the headers above, compute the mask and the refhash
rule abundance_mask:
    input:
        os.path.join(OUTDIR,"abundances/headers.txt")
    output:
        os.path.join(OUTDIR,"abundances/mask_refhash.npz")

    log:
        mask = os.path.join(OUTDIR,"log/abundance/mask.log"),
        o = os.path.join(OUTDIR,"log/abundance/mask.o"),
        e = os.path.join(OUTDIR,"log/abundance/mask.e")
    params:
        path = os.path.join(SNAKEDIR, "scripts", "abundances_mask.py"),
        walltime = "86400",
        nodes = "1",
        ppn = "4"
    resources:
        mem = "1GB"
    threads:
        4
    conda:
        VAMBCONDAENV

    shell:
        """
        python {params.path} --h {input} --msk {output} --minsize {MIN_CONTIG_SIZE} 2> {log.mask}
        """


# For every sample, compute the abundances given the mask and refhash above
rule bam_abundance:
    input:
        bampath=os.path.join(OUTDIR,"mapped/{sample}.sort.bam"),
        mask_refhash=os.path.join(OUTDIR,"abundances/mask_refhash.npz")
    output:
        os.path.join(OUTDIR,"abundances/{sample}.npz")
    params:
        path = os.path.join(SNAKEDIR, "scripts", "write_abundances.py"),
        walltime = "86400",
        nodes = "1",
        ppn = "4"
    resources:
        mem = "1GB"
    threads:
        4
    conda:
        VAMBCONDAENV
    log:
        bam = os.path.join(OUTDIR,"log/abundance/bam_abundance_{sample}.log"),
        o = os.path.join(OUTDIR,"log/abundance/{sample}.bam_abundance.o"),
        e = os.path.join(OUTDIR,"log/abundance/{sample}.bam_abundance.e")

    shell:
        """
        python {params.path} --msk {input.mask_refhash} --b {input.bampath} --min_id {MIN_IDENTITY} --out {output} 2> {log.bam}
        """