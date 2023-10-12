WORKDIR=/home/users/ffs/projects/pigs/
ROHAN=/home/users/ffs/projects/pigs/bin/rohan/bin/rohan
REF=/home/users/ffs/projects/pigs/input/warthog.fa
CHRS=/steveData/anna/piggy/ABP_RRH/warthog.angsd.scaf
GOOD=/steveData/anna/piggy/ABP_RRH/warthog.angsd.file
BAMLIST=/home/users/renzo/projects/pig/metadata/202304_67allInd_bamList.txt

# Make BAMDIR with links to all bam files and index so that we can work on sample-name only.
BAMDIR=${WORKDIR}input/bams/
mkdir ${BAMDIR}
cd ${BAMDIR}
parallel ln -s {} :::: ${BAMLIST}
parallel ln -s {}.bai :::: ${BAMLIST}

# Make list of sample names.
ls | grep .bai | cut -f 1 -d '.' > bam.names

# Make output directory for each sample
parallel mkdir ${WORKDIR}output/filt/{} :::: ${BAMDIR}bam.names

# Run ROHan with default parameters (rohmu 2e-5).
parallel -j 10 nohup nice ${ROHAN} \
    -t 10 \
    --rohmu 2e-5 \
    --auto ${CHRS} \
    --map ${GOOD} \
    -o ${WORKDIR}output/filt/{}/{}_rohan_filt ${REF} ${BAMDIR}{}.Warthog.bam \
    \> ${WORKDIR}output/filt/{}/{}_rohan_filt.log :::: ${BAMDIR}bam.names

### Change rohmu to 1e-4
# Make rohmu2e-5 directory in each output directory and copy everything into rohmu2e-5
parallel mkdir ${WORKDIR}output/filt/{}/rohmu2e-5 :::: ${BAMDIR}bam.names
parallel cp ${WORKDIR}output/filt/{}/* ${WORKDIR}output/filt/{}/rohmu2e-5/ :::: ${BAMDIR}bam.names

# Rerun with rohmu set to 1e-4 skipping the hEst esitmate (-hmm, uses the prev hEst estimates).
nohup parallel nohup ${ROHAN} \
    -t 10 \
    --rohmu 1e-4 \
    --auto ${CHRS} \
    --map ${GOOD} \
    --hmm \
    -o ${WORKDIR}output/filt/{}/{}_rohan_filt ${REF} ${BAMDIR}{}.Warthog.bam \
    \> ${WORKDIR}output/filt/{}/{}_rohan_filt.log :::: ${BAMDIR}bam.names