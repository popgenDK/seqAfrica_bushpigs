library(data.table)

rohdist <- function(respre){
    mid <- fread(paste0(respre, '.mid.hmmp.gz'), da=F)
    colnames(mid)[1] <- 'CHR'
    
    # Fin total length of genome
    chrs <- unique(mid$CHR)
    genomelength <- data.frame()
    for (chr in chrs){
        midchr <- mid[mid$CHR==chr,]
        genomelength <- rbind(genomelength,
            data.frame('chr'=chr, 'length'=max(midchr$END)-min(midchr$BEGIN)))
    }
    totlength <- sum(genomelength$length)

    # Group ROHS into custom groups and calculate 
    rohs <- fread(paste0(respre, '.mid.hmmrohl.gz'), da=F)
    if (nrow(rohs)>0){
        rohs$lengthgroup <- cut(rohs$ROH_LENGTH, c(1,2,5,10,300)*1e6, include.lowest=T)
        return(
            tapply(rohs$ROH_LENGTH,rohs$lengthgroup, sum) / totlength
        )
    } else {return(c(0,0,0,0))}
}
