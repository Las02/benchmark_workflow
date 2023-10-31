
# Index resulting contig-file with minimap2
rule index:
    input:
        contigs = os.path.join(OUTDIR,"contigs.flt.fna.gz")
    output:
        mmi = os.path.join(OUTDIR,"contigs.flt.mmi")
    params:
        walltime="864000",
        nodes="1",
        ppn="1"
    resources:
        mem="90GB"
    threads:
        1
    log:
        out_ind = os.path.join(OUTDIR,"log/contigs/index.log"),
        o = os.path.join(OUTDIR,"log/contigs/index.o"),
        e = os.path.join(OUTDIR,"log/contigs/index.e")
 
    envmodules:
        config['moduleenvs']['minimap2']
    #conda: 
    #    "envs/minimap2.yaml"
    shell:
        "minimap2 -I {INDEX_SIZE} -d {output} {input} 2> {log.out_ind}"

# This rule creates a SAM header from a FASTA file.
# We need it because minimap2 for truly unknowable reasons will write
# SAM headers INTERSPERSED in the output SAM file, making it unparseable.
# To work around this mind-boggling bug, we remove all header lines from
# minimap2's SAM output by grepping, then re-add the header created in this
# rule.
rule dict:
    input:
        contigs = os.path.join(OUTDIR,"contigs.flt.fna.gz")
    output:
        dict = os.path.join(OUTDIR,"contigs.flt.dict")  
    params:
        walltime="864000",
        nodes="1",
        ppn="1"
    resources:
        mem="10GB"
    threads:
        1
    log:
        out_dict= os.path.join(OUTDIR,"log/contigs/dict.log"),
        o = os.path.join(OUTDIR,"log/contigs/dict.o"),
        e = os.path.join(OUTDIR,"log/contigs/dict.e")
    envmodules:
        config['moduleenvs']['samtools']
    #conda:
    #    "envs/samtools.yaml"
    shell:
        "samtools dict {input} | cut -f1-3 > {output} 2> {log.out_dict}"

# Generate bam files 
rule minimap:
    input:
        fq = lambda wildcards: sample2path[wildcards.sample],
        mmi = os.path.join(config['outdir'],"contigs.flt.mmi"),
        dict = os.path.join(config['outdir'],"contigs.flt.dict")
    output:
        bam = temp(os.path.join(config['outdir'],"mapped/{sample}.bam"))
    params:
        walltime="864000",
        nodes="1",
        ppn=MM_PPN
    resources:
        mem=MM_MEM
    threads:
        int(MM_PPN)
    log:
        out_minimap = os.path.join(config['outdir'],"log/map/{sample}.minimap.log"),
        o = os.path.join(config['outdir'],"log/map/{sample}.minimap.o"),
        e = os.path.join(config['outdir'],"log/map/{sample}.minimap.e")
    envmodules:
        config['moduleenvs']['minimap2']

    shell:
        # See comment over rule "dict" to understand what happens here
        "minimap2 -t {threads} -ax sr {input.mmi} {input.fq} -N 5"
        " | grep -v '^@'"
        " | cat {input.dict} - "
        " | samtools view -F 3584 -b - " # supplementary, duplicate read, fail QC check
        " > {output.bam} 2> {log.out_minimap}"