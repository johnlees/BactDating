#' Root to tip correlation
#' @param tree Phylogenetic tree
#' @param date Dates of sampling
#' @param rate Evolutionary rate, estimated unless provided
#' @param permTest Number of permutations to perform to compute the p-value using a permutation test
#' @param showFig Whether or not to show the root-to-tip regression figure
#' @param colored Whether or not to use colors illustrating dates
#' @param showPredInt To show 95percent confidence intervals of a strict clock model, can be 'poisson' or 'gamma'
#' @param showText Whether to show the title and axis labels
#' @param showTree Whether to show the tree or not
#' @return List containing estimated clock rate, date of origin and p-value
#' @importFrom graphics abline
#' @importFrom grDevices rgb
#' @export
roottotip = function(tree,date,rate=NA,permTest=10000,showFig=T,colored=T,showPredInt='gamma',showText=T,showTree=T)
{
  if (!is.rooted(tree)) warning('Warning: roottotip was called on an unrooted input tree. Consider using initRoot first.\n')
  if (sum(tree$edge.length)<5) warning('Warning: input tree has small branch lengths. Make sure branch lengths are in number of substitutions (NOT per site).\n')
  #Rerranging of dates, if needed
  if (!is.null(names(date))) date=findDates(tree,date)

  if (var(date,na.rm=T)==0 && is.na(rate)) {warning('Warning: All dates are identical.\n');return(list(rate=NA,ori=NA,pvalue=NA))}
  n=length(date)
  ys=leafDates(tree)
  if (is.na(rate)) {
    res=lm(ys~date)
  }
  else {
    res=lm(I(ys-rate*date)~1)
    res$coefficients=c(res$coefficients,rate)
  }
  ori=-coef(res)[1]/coef(res)[2]
  rate=coef(res)[2]
  r2=summary(res)$r.squared
  correl=cor(date,ys,use='complete.obs')
  #pvalue=summary(res)$coefficients[,4][2]
  #print(c(r2,correl^2))#Equal

  pvalue=0
  for (i in 1:permTest) {
    date2=sample(date,n,replace=F)
    correl2=cor(date2,ys,use='complete.obs')
    if (correl2>correl) pvalue=pvalue+1/permTest
  }

  if (rate<0) {warning('The linear regression suggests a negative rate.');return(list(rate=rate,ori=ori,pvalue=pvalue))}
  if (showFig==F) return(list(rate=rate,ori=ori,pvalue=pvalue))
  par(xpd=NA,oma = c(0, 0, 2, 0))
  if (colored) {
    normed=(date-min(date,na.rm=T))/(max(date,na.rm=T)-min(date,na.rm=T))
    cols=rgb(ifelse(is.na(normed),0,normed),ifelse(is.na(normed),0.5,0),1-ifelse(is.na(normed),1,normed),0.5)
  } else cols='black'
  if (showTree) {
    par(mfrow=c(1,2))
    plot(tree,show.tip.label = F)
    if (colored) tiplabels(col=cols,pch=19)
    axisPhylo(1,backward = F)
  }
  plot(date,ys,col=cols,xlab=ifelse(showText,'Sampling date',''),ylab=ifelse(showText,'Root-to-tip distance',''),xaxs='i',yaxs='i',pch=19,ylim=c(0,max(ys)),xlim=c(ori,max(date,na.rm = T)))
  #text(date,ys,labels=1:length(date))
  par(xpd=F)
  abline(res,lwd=2)
  xs=seq(ori,max(date,na.rm = T),0.1)
  plim=0.05
  if (showPredInt=='poisson') {
    lines(xs,qpois(  plim/2,(xs-ori)*rate),lty='dashed')
    lines(xs,qpois(1-plim/2,(xs-ori)*rate),lty='dashed')
  }
  if (showPredInt=='gamma') {
    lines(xs,qgamma(  plim/2,shape=(xs-ori)*rate,scale=1),lty='dashed')
    lines(xs,qgamma(1-plim/2,shape=(xs-ori)*rate,scale=1),lty='dashed')
  }
  if (showText) {
  if (pvalue==0) mtext(sprintf('Rate=%.2e,MRCA=%.2f,R2=%.2f,p<%.2e',rate,ori,r2,1/permTest), outer = TRUE, cex = 1.5)
  else           mtext(sprintf('Rate=%.2e,MRCA=%.2f,R2=%.2f,p=%.2e',rate,ori,r2,pvalue), outer = TRUE, cex = 1.5)
  }
  return(list(rate=rate,ori=ori,pvalue=pvalue))
}

#' Initial tree rooting based on best root-to-tip correlation
#' @param phy An unrooted phylogenetic tree
#' @param date Dates of sampling
#' @param mtry Average number of rooting attempts per branch
#' @param useRec Whether or not to use results from previous recombination analysis
#' @return Rooted tree
#' @export
initRoot = function(phy,date,mtry=10,useRec=F) {
  #Rerranging of dates, if needed
  if (!is.null(names(date))) date=findDates(tree,date)

  n=length(date)
  bestcorrel=-Inf
  denom=mean(phy$edge.length)
  for (w in c(1:Ntip(phy),Ntip(phy)+(2:Nnode(phy)))) {
    if (w<=Ntip(phy)) tree=root(phy,outgroup=w,resolve.root = T) else tree=root(phy,node=w,resolve.root = T)
    wi=which(tree$edge[,1]==Ntip(tree)+1)
    toshare=sum(tree$edge.length[wi])
    attempts=max(1,ceiling(mtry*toshare/denom))
    for (a in 1:attempts) {
      tree$edge.length[wi]=toshare*c(a,attempts+1-a)/(attempts+1)
      #ys=leafDates(tree)
      ys=allDates(tree)[1:n]#This is faster
      correl=suppressWarnings(cor(date,ys,use='complete.obs'))
      if (is.na(correl)) correl=-Inf
      if (correl>bestcorrel) {bestcorrel=correl;best=c(w,a,attempts)}
    }
  }
  if (correl==-Inf) {#This happens for example if all dates are identical
    best=c(1,1,1)
  }

  w=best[1];a=best[2];attempts=best[3]
  if (useRec==F) {
    #Rooting without recombination
    if (w<=Ntip(phy)) tree=root(phy,outgroup=w,resolve.root = T) else tree=root(phy,node=w,resolve.root = T)
    wi=which(tree$edge[,1]==Ntip(tree)+1)
    tree$edge.length[wi]=sum(tree$edge.length[wi])*c(a,attempts+1-a)/(attempts+1)

  } else {
    #Rooting with recombination - need to be careful to keep correct unrec values on correct branch
    phy$node.label=sprintf('n%d',1:Nnode(phy))
    edgenames=cbind(c(phy$tip.label,phy$node.label)[phy$edge[,1]],c(phy$tip.label,phy$node.label)[phy$edge[,2]])
    unrec=phy$unrec
    unrecbest=unrec[which(phy$edge[,2]==w)]
    if (w<=Ntip(phy)) tree=root(phy,outgroup=w,resolve.root=T,edgelabel=F) else tree=root(phy,node=w,resolve.root=T,edgelabel=F)
    wi=which(tree$edge[,1]==Ntip(tree)+1)
    tree$edge.length[wi]=sum(tree$edge.length[wi])*c(a,attempts+1-a)/(attempts+1)
    tree$unrec=rep(NA,nrow(tree$edge))
    tree$unrec[wi]=unrecbest
    for (i in 1:nrow(tree$edge)) {
      nams=c(tree$tip.label,tree$node.label)[tree$edge[i,]]
      for (j in 1:nrow(edgenames)) if (setequal(nams,edgenames[j,])) {tree$unrec[i]=unrec[j];break}
    }
  }
  return(tree)
}

#' Compute dates of leaves for a given tree
#' @param phy Tree
#' @return Dates of leaves
#' @export
leafDates = function (phy) {
  rootdate=phy$root.time
  if (is.null(rootdate)) rootdate=0
  nsam=length(phy$tip.label)
  dates=rep(rootdate,nsam)
  for (i in 1:nsam) {
    w=i
    while (1) {
      r=which(phy$edge[,2]==w)
      if (length(r)==0) break
      dates[i]=dates[i]+phy$edge.length[r]
      w=phy$edge[r,1]
    }
  }
  return(dates)
}

#' Compute dates of leaves and internal nodes for a given tree
#' @param phy Tree
#' @return Dates of leaves and internal nodes
#' @export
allDates = function (phy) {
  rootdate=phy$root.time
  if (is.null(rootdate)) rootdate=0
  return(rootdate+unname(dist.nodes(phy)[Ntip(phy)+1,]))
  #o=rev(postorder(phy))#preorder
  #n=Ntip(phy)+Nnode(phy)
  #dates=rep(NA,n)
  #dates[Ntip(phy)+1]=rootdate
  #for (i in o) {
  #  dates[phy$edge[i,2]]=dates[phy$edge[i,1]]+phy$edge.length[i]
  #}
  #return(dates)
}

#' Compute dates of internal nodes for a given tree
#' @param phy Tree
#' @return Dates of internal nodes
#' @export
nodeDates = function (phy) {
  rootdate=phy$root.time
  if (is.null(rootdate)) rootdate=0
  #return(rootdate+dist.nodes(phy)[Ntip(phy)+1,])#This is not faster
  nsam=length(phy$tip.label)
  dates=rep(rootdate,nsam-1)
  for (i in 2:(nsam-1)) {
    w=i+nsam
    while (1) {
      r=which(phy$edge[,2]==w)
      if (length(r)==0) break
      dates[i]=dates[i]+phy$edge.length[r]
      w=phy$edge[r,1]
    }
  }
  return(dates)
}

findDates = function(tree,dates)
{
  date2=rep(NA,Ntip(tree))
  for (i in 1:Ntip(tree)) {
    wi=which(names(dates)==tree$tip.label[i])
    if (length(wi)>1) wi=wi[1]
    if (length(wi)==1) date2[i]=dates[wi]
  }
  return(date2)
}

