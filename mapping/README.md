# Mapping and filtering of pigs

The following describes the commands used to identify/verify adapters, map, and filter BAMs for one or more batches of samples.

-------------------------------------------------------------------------------

## 1. Software used

 * paleomix, rev. 36ffe7c
 * python v3.9.9
 * adapterremoval v2.3.2
 * bwa v0.7.17
 * bwa-mem2 v2.2.1
 * samtools v1.11

### 1.1. Python modules

 * coloredlogs
 * pysam
 * ruamel.yaml

See `install/scripts.requirements.txt` for exact module versions used.

-------------------------------------------------------------------------------
## 2. Overall workflow

### 2.1. Construction of `paleomix bam` YAML files

The YAML configuration files for the `paleomix bam` command are required not only for running the mapping pipeline, but are also used by the adapter identification step to locate PE FASTQ files.

Initial YAML files were generated as follows:

```bash
    paleomix bam makefile > project.yaml
    python3 batch_1.samples/samples_inhouse_tsv_to_yaml.py batch_1.samples/samples_inhouse_v3.tsv >> project.yaml
    python3 batch_1.samples/samples_ncbi_tsv_to_yaml.py batch_1.samples/samples_ncbi_v1.tsv >> project.yaml
```

The YAML files were tweaked to minimize read filtering and trimming of low quality bases.

-------------------------------------------------------------------------------

### 2.2. Identification of adapters

To ensure that the correct adapter sequences were trimmed from all samples, `AdapterRemoval --identify-adapters` was run on all PE reads and the output was compared with the recommended [BGI](https://en.mgi-tech.com/Download/download_file/id/71) or [Illumina](https://emea.support.illumina.com/bulletins/2016/12/what-sequences-do-i-use-for-adapter-trimming.html) adapters sequences for trimming:

    Illumina forward: AGATCGGAAGAGCACACGTCTGAACTCCAGTCA
    Illumina reverse: AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT

    BGI forward: AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA
    BGI reverse: AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG

A makefile is provided for running the scripts for each batch:

```bash
    make adapters BATCH=batch_1
    make adapters BATCH=batch_2
```

Individual output files from `AdapterRemoval --identify-adapters` are written to `${BATCH}.adapters/` and the resulting `${BATCH}.adapters.tsv` files contains attemped automatic classifications of adapter sequences, reporting the best match with either BGI or Illumina sequences.

The following adapters were identified and the AdapterRemoval settings `--adapter1` and `--adapter2` were updated in the YAML files using those sequences:

* Batch 1: Standard Illumina and BGI adapters were used (see above)
* Batch 2: Standard Illumina adapters

-------------------------------------------------------------------------------

### 2.3. Read mapping

Read mapping was performed using a development version of [PALEOMIX](https://github.com/mikkelschubert/paleomix). Minimal filtering is performed during this run (see above), with the final BAM file containing all input reads (some pairs of which may be merged into a single sequence), except for empty reads.

A makefile is provided for running the pipeline for each batch:

```bash
    make mapping BATCH=batch_1
    make mapping BATCH=batch_2
```

The output BAMs, temporary files, and logs are written to `${BATCH}.raw_bams/`.

-------------------------------------------------------------------------------

### 2.4. Filtering and SAMTools statistics

Run the SnakeMake file to filter the BAMs and to collect SAMTools statistics:

```bash
    make filtering BATCH=batch_1
    make filtering BATCH=batch_2
```

This writes the filtered BAMs and statistics files to `${BATCH}/`.

-------------------------------------------------------------------------------

### 2.6. QC reports

Run the SnakeMake file to generate QC reports using FastQC:

```bash
    make qc_1_fastq BATCH=batch_2
    make qc_2_mapstat BATCH=batch_2
    make qc_3_all BATCH=batch_2
```

* Batch 1: QC was performed post-mapping/filtering by Kristian E.H.
* Batch 2: A variety of issues were observed in the FastQC reports.


#### 2.6.1. QC issues with BPigZim49001 and BPigRSA49002 (batch 2)

Issues observed with FastQC for BPigZim49001 and BPigRSA49002:
 1. Systematic biases in GC content across the reads.
 2. A large divergence in average base composition at the final base
 3. Peaks in GC content distribution at ~70% for R1 and at 100% for R2
 4. The presense of TruSeq Adapter (Index 9) sequence in R1 files, which were
    observed to ~100% Gs in R2 files, suggesting that nothing was sequenced.

As the TruSeq Adapters did not map, it was decided to trim the last base from all reads and re-do mapping and QC (steps 2.3 to 2.6). Trimming was carried out using the following command using `seqtk` (rev. b98236d):

```bash
    pigz -cd "${source}" | seqtk trimfq -e 1 - | pv -l | pigz > "${target}"
```

Trimmed samples were given the postfix `t` (e.g. `BPigZim49001t`) and QC was run including both the original FASTQs/BAMs and the trimmed FASTQs and corresponding BAMs.

