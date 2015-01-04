# will save ALL needed tarballs to destdir
# for tool_dependency use
# ross lazarus
# bah! humbug!
# dec 24 2014
#pec_2.3.7       survival_2.37-7 lars_1.2        glmnet_1.9-8    Matrix_1.1-4   
#codetools_0.2-9 foreach_1.4.2   grid_3.1.0      iterators_1.0.7 lattice_0.20-29 lava_1.2.6      prodlim_1.4.3



destdir = '~/galaxy_tool_source/RELEASE_2_14/rglasso'
packages = c('Matrix','pec','glmnet','prodlim')
#  <package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/Rcpp_0.11.3.tar.gz?raw=true</package>
ps='<package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/'
pe='?raw=true</package>'

library("pkgDepTools")
library("Biobase")
## library("Rgraphviz")

if(require("BiocInstaller")){
  print("BiocInstaller is loaded correctly")
} else {
  print("trying to install BiocInstaller")
  install.packages("BiocInstaller")
  if(require(BiocInstaller)){
    print("BiocInstaller installed and loaded")
  } else {
    stop("could not install BiocInstaller")
  }
}

setRepositories(ind=1:2)
chooseBioCmirror(ind=7,graphics=F) # canberra - use eg 1 for FredHutch
chooseCRANmirror(ind=5,graphics=F) # Melbourne - use 96 for texas

packageExpand = function(packagelist,fl) {
  res = NA
  print(packagelist)
  for (i in c(1:length(packagelist))) {
    s = packagelist[i]
    print(s)
    ls = nchar(s)
    j = which(substr(fl,1,ls) == s,arr.ind=T)
    print(j)
    fullname = fl[j]
    print(fullname)
    row = paste(ps,fullname,pe,sep='')
    res = append(res,row)
    }
  return(res)
}

install.packages(pkgs=packages,destdir=destdir,lib=destdir, type='source',Ncpus=4, dependencies=T,clean=F, repos=biocinstallRepos())
flist = list.files(destdir)
print.noquote(flist)
biocUrl <- biocinstallRepos()["BioCsoft"]
print('making dependency graph - takes a while')
allDeps <- makeDepGraph(biocinstallRepos(), type="source",keep.builtin=TRUE, dosize=FALSE)
## this is a large structure and takes a long time to build
for (i in c(1:length(packages))) { 
  package = packages[i]
  io = getInstallOrder(package, allDeps, needed.only=FALSE)
  print(paste('For',package,'order is',paste(io$packages,collapse=',')))
  res = packageExpand(packagelist=io$packages,fl=flist)
  print(res)
}


