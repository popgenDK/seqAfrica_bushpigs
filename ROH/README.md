# ROH (Runs of Homozygosity)

## Introduction

The pipelien for ROH analysis of individuals in African bush pig project.

## Requirement

- GNU parallel
- plink == 1.9.0
- R >= 4.0
- R library:
  - snpStats
  - windowscanr
  - tidyverse
  - RColorBrewer
  - argparse
  - ggplot2
  - data.table
  - ggthemes

## Steps

Before you run the pipeline, please preprocess your SNP data, like quality control or data filtering. Then please generate the PLINK (ver 1.9.0) files (`--make-bed`). The PLINK files should be `/path/to/preprocessed/bfile.bed` (and other suffixes).

Then please select the individuals in which you're interested. It should be in `.fam` (PLINK) format, like `/path/to/target/individual/list/xxx.fam`

Then please run as following steps:
**NOTE: please check the plink parameters in `.sh` scripts, or modify plotting parameters in R scripts if they don't fit your data well.**

```bash
# step 01: filter out invalid sites
bash 01.plink_filter.sh /path/to/preprocessed/bfile /path/to/target/individual/list/xxx.fam
```

```bash
# step 02: ROH for each individual
bash 02.individual_plink.sh /path/to/target/individual/list/xxx.fam
```

```bash
# step 03: draw ROH region plot across each chromosomes of each individual
sh 03.ROH_plots.sh
```

```bash
# step 04: draw ROH proportion plot of all individuals
sh 04.ROH_proportion.sh
```

