# Merge the abundances to a single Abundance object and save it
rule create_abundances:
    input:
        npzpaths=expand(os.path.join(OUTDIR,"abundances","{sample}.npz"), sample=IDS),
        mask_refhash=os.path.join(OUTDIR,"abundances","mask_refhash.npz")
    output:
        os.path.join(OUTDIR,"abundance.npz")
    params:
        path = os.path.join(SNAKEDIR, "scripts", "create_abundances.py"),
        abundance_dir = os.path.join(OUTDIR, "abundances"),
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
        create_abs = os.path.join(OUTDIR,"log/abundance/create_abundances.log"),
        o = os.path.join(OUTDIR,"log/abundance/create_abundances.o"),
        e = os.path.join(OUTDIR,"log/abundance/create_abundances.e")

    shell:
        "python {params.path} --msk {input.mask_refhash} --ab {input.npzpaths} --min_id {MIN_IDENTITY} --out {output} 2> {log.create_abs} && "
        "rm -r {params.abundance_dir}"
