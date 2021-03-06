# will save ALL needed tarballs to destdir
# for tool_dependency use
# ross lazarus
# bah! humbug!
# dec 24 2014
#pec_2.3.7       survival_2.37-7 lars_1.2        glmnet_1.9-8    Matrix_1.1-4   
#codetools_0.2-9 foreach_1.4.2   grid_3.1.0      iterators_1.0.7 lattice_0.20-29 lava_1.2.6      prodlim_1.4.3



destdir = '~/galaxy_tool_source/RELEASE_2_14/rglasso'
libdir = '~/galaxy_tool_source/RELEASE_2_14/rglasso'
our_packages = c('e1071','caret','pROC','Hmisc','pracma','survival','lars','glmnet','pec')
#  <package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/Rcpp_0.11.3.tar.gz?raw=true</package>
ps='<package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/rglasso/'
pe='?raw=true</package>'

library("pkgDepTools")
library("Biobase")

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
  res = c()
  for (i in c(1:length(packagelist))) {
    s = packagelist[i]
    ls = nchar(s)
    spos = which(substr(fl,1,ls) == s,arr.ind=T)
    lspos = length(spos)
    if (lspos > 0)
      {
      fullname = fl[spos[lspos]] ## take last one
      ## print.noquote(paste('### spos=',paste(spos,collapse=','),'for',fullname))
      if (grepl('*.gz',fullname)) {
           row = paste(ps,fullname,pe,sep='')
           res = append(res,row)
           }
      }
    }
  return(res)
}

getPackages <- function(packs)
  {
  packages <- unlist(tools::package_dependencies(packs, available.packages(),
        which=c("Depends", "Imports"), recursive=TRUE))
  packages <- union(packs, packages)
  packages
  }

packages <- getPackages(our_packages)
# > packages
# [1] "Survival"     "lars"         "glmnet"       "pec"          "Matrix"      
# [6] "utils"        "methods"      "graphics"     "grid"         "stats"       
# [11] "lattice"      "grDevices"    "prodlim"      "foreach"      "rms"         
# [16] "survival"     "codetools"    "iterators"    "KernSmooth"   "lava"        
# [21] "Hmisc"        "SparseM"      "quantreg"     "nlme"         "rpart"       
# [26] "polspline"    "multcomp"     "splines"      "Formula"      "latticeExtra"
# [31] "cluster"      "nnet"         "acepack"      "foreign"      "numDeriv"    
# [36] "mvtnorm"      "TH.data"      "sandwich"     "RColorBrewer" "zoo"         
# install.packages(pkgs=packages,destdir=libdir,lib=libdir, type='source',Ncpus=4, dependencies=T,clean=F, repos=biocinstallRepos())
download.packages(pkgs=packages,destdir=libdir, type='source',repos=biocinstallRepos())
libfiles = list.files(libdir)
fdet = file.info(libfiles)
details = fdet[with(fdet, order(as.POSIXct(mtime),decreasing=T)), ]
flist = rownames(details)
print.noquote(flist)
biocUrl <- biocinstallRepos()["BioCsoft"]
print('making dependency graph - takes a while')
allDeps <- makeDepGraph(biocinstallRepos(), type="source",keep.builtin=TRUE, dosize=FALSE)
## this is a large structure and takes a long time to build
res = c()
for (i in c(1:length(our_packages))) { 
  package = our_packages[i]
  io = getInstallOrder(package, allDeps, needed.only=FALSE)
  ares = packageExpand(packagelist=io$packages,fl=flist)
  res = append(res,ares)
  }
ures = unique(res)
outR = paste(destdir,'lasso_deps.R',sep='/')
write.table(ures,file=outR,quote=F,sep='\t',row.names=F)
print.noquote(ures)
sessionInfo()





