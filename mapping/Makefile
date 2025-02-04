.PHONEY = adapters

# Override by running `make BATCH=batch_1`
BATCH := batch_1
# Number of cores/threads
CORES := 30

# The current group/species
GROUP := $(shell basename $(shell readlink -f .))
# Out-of-tree storage location for data
STORAGE := /projects/seqafrica/scratch/mapping/${GROUP}

# Find YAML files for this batch
YAMLFILES := $(shell ls ${BATCH}.mapping.*yaml)

# Prefix that ensures that commands run with activated modules
ACTIVATED := source install/activate.sh && nice -19 ionice -c 3


#############################################################################
# Misc

help:
	@echo 'Usage: make <adapters/mapping/preliminary/filtering> BATCH=$${batch}'
	@echo "  e.g. make mapping BATCH=batch_1"

./${BATCH}%:
	mkdir -p "${STORAGE}/$@"
	ln -sf "${STORAGE}/$@"

#############################################################################
## 1. Check adapters and perform basic validation of FASTQ files

adapters: ./${BATCH}.adapters/
	${ACTIVATED} python3 install/scripts/identify_adapters.py $(YAMLFILES) --output ${BATCH}.adapters
	${ACTIVATED} python3 install/scripts/classify_adapters.py ${BATCH}.adapters | tee ${BATCH}.adapters.tsv

#############################################################################
## 2. Preliminary QC of FASTQ files

${BATCH}.qc.prior.yaml: ${YAMLFILES}
	# Generate configuration file
	${ACTIVATED} python3 install/qc_workflow/scripts/make_config.py \
		--paleomix_yaml ${YAMLFILES} \
		--output_yaml "$@" \
		--outputdir_snk "${BATCH}.qc"

${BATCH}.qc.main.yaml: ${YAMLFILES}
	# Generate configuration file
	${ACTIVATED} python3 install/qc_workflow/scripts/make_config.py \
		--paleomix_yaml ${YAMLFILES} \
		--bams ${BATCH}/*.bam \
		--close_ref_name "SusScrofa" \
		--distant_ref_name "Warthog" \
		--perfect_bam_name "RRivNIG46518"  \
		--output_yaml "$@" \
		--outputdir_snk "${BATCH}.qc"
	#	 --exclude A B C


QC_PIPELINE := ${ACTIVATED} snakemake --use-conda -p -c ${CORES} \
	--conda-prefix ./install/qc_workflow.conda/ \
	--snakefile ./install/qc_workflow/Snakefile \
	--rerun-incomplete --keep-going

qc_1_fastq: ${BATCH}.qc.prior.yaml ./${BATCH}.qc/
	${QC_PIPELINE} --configfile "${BATCH}.qc.prior.yaml" -- RUN_multiqc_pre

qc_2_mapstat: ${BATCH}.qc.main.yaml ./${BATCH}.qc/
	${QC_PIPELINE} --configfile "${BATCH}.qc.main.yaml" -- RUN_json

qc_3_all: ${BATCH}.qc.main.yaml ./${BATCH}.qc/
	${QC_PIPELINE} --configfile "${BATCH}.qc.main.yaml" -- RUN_all


#############################################################################
## Mapping

mapping: ./${BATCH}.mapping/
	# Support the case where output is a symlink to a removed folder
	mkdir -p ${BATCH}.mapping/logs
	${ACTIVATED} paleomix.36ffe7c bam run \
		--destination ${BATCH}.mapping/ \
		--temp-root ${BATCH}.mapping/temp \
		--log-file ${BATCH}.mapping/logs/${HOSTNAME}_$(shell date +"%Y%m%d_%H%M%S").txt \
		$(YAMLFILES)

filtering: ./${BATCH}/
	${ACTIVATED} snakemake \
		--snakefile install/scripts/Snakefile.filter_bams \
		--config batch=${BATCH} src_dir=${BATCH}.mapping \
		-j ${CORES} -p

clipped_bases: ./${BATCH}/
	${ACTIVATED} python3 install/scripts/count_softclipped_bp_in_bam.py ${BATCH}/ \
		| tee ${BATCH}.clipped_bases.tsv
