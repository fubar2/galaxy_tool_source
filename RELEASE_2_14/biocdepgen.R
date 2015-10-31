# for tool_dependency generation
# replace ps, destdir, our_packages etc to suit your own needs
# ross lazarus
# bah! humbug!
# dec 24 2014


destdir = '~/ross/galaxy_tool_source/RELEASE_2_14'
libdir = '~/ross/galaxy_tool_source/RELEASE_2_14'
our_packages = c('RColorBrewer','RcppEigen','e1071','caret','pROC','Hmisc','pracma','survival','lars','glmnet','pec')
#  <package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/Rcpp_0.11.3.tar.gz?raw=true</package>
ps='<package>https://github.com/fubar2/galaxy_tool_source/blob/master/RELEASE_2_14/'
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


packageExpand = function(packagelist,fl,ps,pe) {
  res = c()
  for (i in c(1:length(packagelist))) {
    s = packagelist[i]
    ls = nchar(s)
    spos = which(substr(fl,1,ls) == s,arr.ind=T)
    lspos = length(spos)
    if (lspos > 0)
      {
      fullname = fl[spos] ## take last one
      ## print.noquote(paste('### spos=',paste(spos,collapse=','),'for',fullname))
      if (grepl('*.gz',fullname)) {
           row = paste(ps,fullname,pe,sep='')
           res = append(res,row)
           } else {
            print(paste('### ignoring',fullname))
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

download.packages(pkgs=packages,destdir=libdir, type='source',repos=biocinstallRepos())
flist = list.files(libdir)
print.noquote(flist)
biocUrl <- biocinstallRepos()["BioCsoft"]
print('making dependency graph - takes a while')
allDeps <- makeDepGraph(biocinstallRepos(), type="source",keep.builtin=F, dosize=FALSE)
## this is a large structure and takes a long time to build
res = c()
for (i in c(1:length(our_packages))) { 
  package = our_packages[i]
  io = getInstallOrder(package, allDeps, needed.only=FALSE)
  ares = packageExpand(packagelist=io$packages,fl=flist,ps=ps,pe=pe)
  print(paste('#For',package,'got',paste(ares,collapse=';')))
  res = append(res,ares)
  }
ures = unique(res)
outR = paste(destdir,'rglasso_deps.R',sep='/')
write.table(ures,file=outR,quote=F,sep='\t',row.names=F)
print.noquote(ures)
sessionInfo()

