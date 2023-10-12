library(data.table)

plotROHan <- function(respre, output, ...){
    # Customization
    rohcols <- c("#009E73", "#CC79A7")
    dencol <- '#333333'
    rbPal <- colorRampPalette(c('red','blue'))
    ncolbreaks <- 100
    colorscale <- rbPal(ncolbreaks)

    # Set the different limits from 0 to 1.
    denmin <- 0.05
    denmax <- 0.3
    hetmin <- 0.35
    hetmax <- 0.55
    pROHmin <- 0.6
    pROHmax <- 0.75
    rohmin <- 0.8
    rohmax <- 0.95

    name <- gsub('^.*/([^/]*)$', '\\1', respre)

    # Load .mid.hmmp.gz
    proh <- fread(paste0(respre, '.mid.hmmp.gz'), da=F)
    colnames(proh) <- c('CHR', 'B', 'E', 'pROH', 'pNONROH')
    proh$pROH <- as.numeric(proh$pROH)

    # Load hEst.gz
    hest <- fread(paste0(respre, '.hEst.gz'), da=F)
    colnames(hest)[1:3] <- c('CHR', 'B', 'E')
    hest$len <- hest$E - hest$B
    hest$dens <- hest$VALIDSITES / hest$len
    hmedian <- median(hest$h, na.rm = T)
    hest$hcap <- ifelse(hest$h>hmedian, hmedian, hest$h)
    hest$h_norm <- hest$hcap/hmedian

    # Sanity-check
    if(!nrow(hest) == nrow(proh)){stop(paste0('.mid.hmmp.gz and .hEst.gz does not have same number of entries/rows.'))}

    # Load rohs
    rohs <- fread(paste0(respre, '.mid.hmmrohl.gz'), da=F)
    hasrohs <- F
    if (nrow(rohs)>0){
        hasrohs <- T
        colnames(rohs)[2:4] <- c('CHR', 'B', 'E')
    }

    # Precalc across chromnosomes.
    xlims <- c(min(proh$B), max(proh$E))
    chrs <- unique(proh$CHR)
    dendiff <- denmax-denmin
    hetdiff <- hetmax-hetmin

    # Make plot
    png(output, width = 8, height = 6, res=300, units = 'in')
    par(mar=c(2.5,3,1,0.5), mgp=c(1.6,0.6,0), font.main=1, cex.main=1)
    plot(0,0,col='transparent', xlim=xlims, ylim=c(0, length(chrs)), bty='L', las=1,
        axes=F, xlab='Position (MB)', ylab='', main=name,...)
    for (i in 1:length(chrs)){
        chr <- chrs[i]
        proh_c <- subset(proh, CHR==chr)
        hest_c <- subset(hest, CHR==chr)
        
        # Plot ROHs
        if (hasrohs){
            rohs_c <- subset(rohs, CHR==chr)   
            if (nrow(rohs_c) > 0){
                rohs_c$col <- rohcols[rep(c(1,2), length.out=nrow(rohs_c))]
                rect(rohs_c$B, i-1+rohmin, rohs_c$E, i-1+rohmax, col=rohs_c$col)
            }
        }
        
        # Plot p[ROH]
        proh_c$pROHcol <- colorscale[as.numeric(cut(proh_c$pROH,
            breaks=seq(0,1, length.out=ncolbreaks), include.lowest=T))]
        proh_c[is.na(proh_c$pROHcol), 'pROHcol'] <- 'gray'
        rect(proh_c$B, i-1+pROHmin, proh_c$E, i-1+pROHmax, col=proh_c$pROHcol, lwd=NA)
        
        # Plot hEst
        rect(hest_c$B, i-1+hetmin,
            hest_c$E, i-1+hetmin+hest_c$h_norm*hetdiff+0.01)

        # Plot density
        rect(hest_c$B, i-1+denmin, hest_c$E, i-1+denmin+(hest_c$dens*dendiff), lwd=NA, col=dencol)

        axis(2, at = c(i-1+0.05,i-0.05), labels = c('',''), lwd.ticks = 0)
        axis(2, at = i-0.5, labels = chr, las=1)
    }

    xs <- seq(0, xlims[2], by=50000000)
    axis(1, at=xs, labels = xs/1000000)

    # Custom Legends
    legendcex <- 0.7
    pl <- par()$usr
    xmin <- pl[2]*0.9
    xmax <- pl[2]*0.92
    xmid <- xmin+((xmax-xmin)/2)

    # ROH legend
    text(xmid, pl[4]*0.92*1.02, 'ROH', cex=legendcex)
    rect(c(xmin, xmid), pl[4]*0.9, c(xmid, xmax), pl[4]*0.92, col=rohcols)

    # pROH legend
    ymin <- pl[4]*0.77
    ymax <- pl[4]*0.84
    ys <- seq(ymin, ymax, length.out=length(colorscale))
    rect(xmin, ys[-length(ys)], xmax, ys[-1], lwd=0, col=colorscale)
    rect(xmin, ymin, xmax, ymax, lwd = 0.5)
    text(xmid, ymax*1.02, 'P(ROH)', adj=c(0.5,0), cex=legendcex)
    text(xmax, ymax*1.002, '- 1', adj=0, cex=legendcex)
    text(xmax, ymin*1.005, '- 0', adj=0, cex=legendcex)

    # hEst legend
    hetxs <- seq(xmin, xmax, length.out=5)
    text(xmid, pl[4]*0.69*1.02, 'median-\ncapped hEst', adj=c(0.5,0), cex=legendcex)
    rect(hetxs[-length(hetxs)], pl[4]*0.67, hetxs[-1], pl[4]*0.69)

    # Density
    text(xmid, pl[4]*0.62*1.02, 'snpdens', adj=c(0.5,0), cex=legendcex)
    rect(hetxs[-length(hetxs)], pl[4]*0.60, hetxs[-1], pl[4]*0.62, col=dencol)

    dev.off()
}
