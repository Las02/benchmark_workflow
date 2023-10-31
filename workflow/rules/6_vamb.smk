

rule run_avamb:
    input:
        contigs=os.path.join(OUTDIR,"contigs.flt.fna.gz"),
        abundance=os.path.join(OUTDIR,"abundance.npz")
    output:
        outdir_avamb=directory(os.path.join(OUTDIR,"avamb")),
        clusters_aae_z=os.path.join(OUTDIR,"avamb/aae_z_clusters.tsv"),
        clusters_aae_y=os.path.join(OUTDIR,"avamb/aae_y_clusters.tsv"),
        clusters_vamb=os.path.join(OUTDIR,"avamb/vae_clusters.tsv"),
        contignames=os.path.join(OUTDIR,"avamb/contignames"),
        contiglenghts=os.path.join(OUTDIR,"avamb/lengths.npz")
    params:
        walltime="86400",
        nodes="1",
        ppn=AVAMB_PPN,
        cuda="--cuda" if CUDA else ""
    resources:
        mem=AVAMB_MEM
    threads:
        int(avamb_threads)
    conda:
        VAMBCONDAENV
    log:
        vamb_out=os.path.join(OUTDIR,"tmp/avamb_finished.log"),
        o=os.path.join(OUTDIR,'log','run_avamb.out'),
        e=os.path.join(OUTDIR,'log','run_avamb.err')
    default_target: True
    shell:
        """
        vamb --outdir {output.outdir_avamb} --fasta {input.contigs} -p {threads} --rpkm {input.abundance} -m {MIN_CONTIG_SIZE} --minfasta {MIN_BIN_SIZE}  {params.cuda}  {AVAMB_PARAMS}
        """
   
