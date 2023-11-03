configfile: '../config/config.yaml'
VAMBCONDAENV = 'vamb/4.1.3' # Change to static later
SAMTOOLSENV = "samtools/1.17"
MINIMAP2ENV = "minimap2/2.6"

import re
import os
import sys
import numpy as np
SNAKEDIR = os.path.dirname(workflow.snakefile)

sys.path.append(os.path.join(SNAKEDIR, 'scripts'))


def get_config(name, default, regex):
    res = config.get(name, default).strip()
    m = re.match(regex, res)
    if m is None:
        raise ValueError(
            f"Config option \"{name}\" is \"{res}\", but must conform to regex \"{regex}\"")
    return res


# set configurations
CONTIGS = get_config("contigs", "../config/contigs.txt", r".*") # each line is a contigs path from a given sample
SAMPLE_DATA = config['sample_data']

INDEX_SIZE = config['index_size'] 
MIN_BIN_SIZE = config['min_bin_size']
MIN_CONTIG_SIZE = config['min_contig_size'] 
MIN_IDENTITY = config['min_identity'] 
MM_MEM = config['minimap']['minimap_mem']
MM_PPN = config['minimap']['minimap_ppn']
AVAMB_MEM = config['vamb']['avamb_mem']
AVAMB_PPN = config['vamb']['avamb_ppn']

AVAMB_PARAMS = get_config("avamb_params"," -o C --minfasta 200000  ", r".*")
AVAMB_PRELOAD = get_config("avamb_preload", "", r".*")

MIN_COMP = config['min_comp']#get_config("min_comp", "0.9", r".*")
MAX_CONT = config['max_cont']#get_config("max_cont", "0.05", r".*")

OUTDIR= get_config("outdir", "outdir_avamb", r".*")

try:
    os.makedirs(os.path.join(OUTDIR,"log"), exist_ok=True)
except FileExistsError:
    pass


# parse if GPUs is needed #
AVAMB_PPN = AVAMB_PPN 
AVAMB_GPUS = config['vamb']['avamb_gpus']
CUDA = AVAMB_GPUS > 0

## read in sample information ##

# read in sample2path
IDS = []
sample2path = {}
fh_in = open(SAMPLE_DATA, 'r')
print(SAMPLE_DATA)
for line in fh_in:
    line = line.rstrip()
    fields = line.split('\t')
    IDS.append(fields[0])
    sample2path[fields[0]] = [fields[1], fields[2]]

# read in list of per-sample assemblies
contigs_list = []
fh_in = open(CONTIGS, 'r')
for line in fh_in:
    line = line.rstrip()
    contigs_list.append(line)

# target rule
#rule all:
#    input:
#        contigs=os.path.join(OUTDIR,"contigs.flt.fna.gz"),
#        abundance=os.path.join(OUTDIR,"abundance.npz") 
rule all:
    input:
        clusters_aae_z=os.path.join(OUTDIR,"avamb/aae_z_clusters.tsv"),

include: "rules/1_filter_rename_cat.py"        # Remove each contig with length<2000 | rename them to {Sample}C{ID} | cat all contigs -> file with all contigs together
include: "rules/2_index_and_run_minimap2.py"   # Map the reads to the contigs using minimap2 to produce bam files -> bam file for each sample? eg. both fw/rw reads
include: 'rules/3_sort_bam.py'                 # Sort the bam files -> a bam file for each sample
include: 'rules/4_calculate_abundance.py'      # Calculate the abundance for each bam file -> abundance for each bam file
include: 'rules/5_merge_abundance.py'          # Merge the abundances -> npz file with abundances
include: 'rules/6_vamb.py'                     # Takes the abundance npz file and the contigs and runs bam -> bins

# Input avamb:
#contigs=os.path.join(OUTDIR,"contigs.flt.fna.gz"),
#abundance=os.path.join(OUTDIR,"abundance.npz") 
# Generate the 3 sets of clusters and bins
