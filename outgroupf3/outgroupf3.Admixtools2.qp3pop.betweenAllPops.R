# /usr/bin/env R
library(admixtools)

args <- commandArgs(trailingOnly=T)

inplink <- args[1] #plink file
popinfo <- args[2] #poplist
f2dir <- args[3] #f2 dir
outf <- args[4] #out file
blocklen <- as.double(5e6)
maxmiss <- as.double(0.9)
ncores <- as.integer(40)

#Process data
info <- read.table(popinfo,h=F)
pops <- as.character(info$V2)
inds <- as.character(info$V1)

#Extract f2s
extract_f2(
    pref=inplink,
    outdir=f2dir,
    pops=pops,
    inds=inds,
    maxmiss=maxmiss,
    format="plink",
    blgsize=blocklen,
    fst=TRUE,
    auto_only = FALSE,
    n_cores=ncores
)

#Define pops
pop2=c("Ghana","Togo","Nigeria","Cameroon","EqGuinea","Gabon","Uganda","Ethiopia","Tanzania","Zimbabwe","RSA")
pop3='Madagascar'
pop1='commonWarthog'

#Calculate outgroup f3s
f2_blocks <- f2_from_precomp(f2dir)
out <- f3(f2_blocks, pop1, pop2, pop3)
write.table(out, outf, sep="\t", quote=FALSE, col.names = T, row.names = F)