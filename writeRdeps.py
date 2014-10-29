## freeze some source dependencies for a set of R packages
## required packages are listed ending with a _ followed by any nonsense
## only the package name will be used and it will be matched by
## parsing the cran src or bioconductor svn release tag web pages
## (yay! BeautifulSoup!) and grabbing the relevant ones.
## BioC source is downloaded and packaged up into tarballs
## ready for use as a tool url pointing to a github source   
## needs beautifulsoup v4+ - eg sudo apt-get install python-bs4 for ubuntu 14.04
## ross lazarus me fecit september 2014
## to solve the challenge of preparing a tool_dependencies.xml file for a BioC/R package like shrnaseq


import sys
import os
import base64
import urllib2
from bs4 import BeautifulSoup
import subprocess
import glob
import argparse


default_packageList = """lars_1.2.tar.gz, glmnet_1.9-8.tar.gz,grid_3.1.0.tar.gz, lattice_0.20-29.tar.gz,
getopt_1.20.0.tar.gz,BiocGenerics_0.6.0.tar.gz,IRanges_1.18.2.tar.gz,GenomicRanges_1.12.4.tar.gz,Rcpp_0.10.4.tar.gz,
limma_any.tar.gz,edgeR_any.tar.gz,RcppArmadillo_0.3.900.0.tar.gz,locfit_1.5-9.1.tar.gz,Biobase_2.20.1.tar.gz,
DBI_0.2-7.tar.gz,RSQLite_0.11.4.tar.gz,AnnotationDbi_1.22.6.tar.gz,ggplot2,reshape2,xtable_1.7-1.tar.gz,
XML_3.98-1.1.tar.gz,annotate_1.38.0.tar.gz,genefilter_1.42.0.tar.gz,RColorBrewer_1.0-5.tar.gz,DESeq2_1.0.18.tar.gz,
rjson_0.2.13.tar.gz,e1071_any.tar.gz,caret_any_tar.gz,pROC_any_tar.gz,pracma_any_tar.gz,Hmisc_any_tar.gz,
pec_any_tar.gz"""

### NOTE the actual version numbers are ignored - these were snarfed from one of Bjorn's tools - deseq2 I think :)

def getBioCSource(ppath):
    """
    need to use basic auth because bioc svn is
    password protected to be irritating - readonly:readonly
    once we get the tag's directory, we need to download each entire svn folder
    and write a new tarball with some version info added then remove source
    easiest with wget  -r --no-parent --http-user=USERNAME --http-password=PASSWORD http://SOMETURLTOFILE
    """
    opath = os.path.basename(ppath)
    if opath.endswith('/'):
         opath = opath[:-1] # lose trailing slash
    if os.path.exists(opath):
         print '### looks like %s already exists. Delete to redownload?' % opath
         return
    lfile = '%s/DESCRIPTION' % opath
    dfile = '%s/DESCRIPTION' % ppath
    scl = 'wget --cut-dirs=6 --no-host-directories --http-user=readonly --http-password=readonly --directory-prefix=%s %s' % (opath,dfile)
    cl = scl.split()
    retcode1 = subprocess.call(cl)
    DESC = open(lfile,'r').readlines()
    ver = [x for x in DESC if x.startswith('Version:')][0]
    ver = ver.replace('Version: ','').strip()
    assert len(ver) > 0,'No string starting with Version: in %s' % dfile
    samebase = glob.glob('%s_%s.tar.gz' % (opath,ver))
    if len(samebase) > 0:
        print '### %s found so maybe repo %s ver %s already exists - delete and rerun to rebuild.' % (samebase,opath,ver)
        rcl = 'rm -rf %s/' % opath
        retcode4 = subprocess.call(rcl.split())
        return 99
    scl = 'wget -r --no-parent --cut-dirs=6 --no-host-directories --http-user=readonly --http-password=readonly --directory-prefix=%s %s/ ' % (opath,ppath)
    # seem to need the trailing slash to make --no-parent work right and remove 6 top level dirs BiocGenerics/bioconductor/branches/RELEASE_2_14/madman/Rpacks/
    cl = scl.split()
    retcode2 = subprocess.call(cl)
    tarpath = '%s_%s.tar.gz' % (opath,ver)
    ccl = 'tar -cz .'
    cl = ccl.split()
    tarfile = open(tarpath,'wb')
    retcode3 = subprocess.call(cl,stdout=tarfile,cwd=opath)
    tarfile.close()
    rcl = 'rm -rf %s' % opath
    retcode4 = subprocess.call(rcl.split())

    
def get_Bioc_urls(mirror='',pList=[],get_archives=False):
    """
    need to use basic auth because bioc svn is
    password protected to be irritating - readonly:readonly    request = urllib2.Request(mirror)
    """
    request = urllib2.Request(mirror)
    base64string = base64.encodestring('readonly:readonly') 
    request.add_header("Authorization", "Basic %s" % base64string)   
    req = urllib2.urlopen(request)
    fl = req.read().strip()
    hrefs = []
    soup = BeautifulSoup(fl)
    for link in soup.find_all('a'):
        l = link.get('href')
        if (not l.startswith('.')) and l.endswith('/'):
            hrefs.append(l[:-1])
    print '### bioc hrefs',hrefs
    ppaths = []
    if len(pList) == 0: # all please
        print '### getting ALL bioc!'
        ppaths = [ os.path.join(mirror,x) for x in hrefs]
        if get_archives:
           for ppath in ppaths: 
               print '### BioC checking',ppath
               rc = getBioCSource(ppath)
               ppaths.append(ppath) # path containing archive
    else:
        for p in pList:
            res = [x for x in hrefs if x.find(p) == 0]
            res2 = [x for x in res if len(x.split('_')[0]) == len(p)]
            if (len(res2) > 0):
               ppath = os.path.join(mirror,res[0])
               if get_archives:
                   rc = getBioCSource(ppath)
                   ppaths.append(ppath) # path containing archive
                   print '### BioC res=',res,'saved',p
    hrefs = [os.path.join(mirror,x) for x in hrefs]
    return (hrefs,ppaths)

def get_CRAN_urls(mirror='',pList=[],get_archives=False):
 
    urlpath = urllib2.urlopen(mirror)
    fl = urlpath.read().decode('utf-8')
    request = urllib2.Request(mirror)
    o = urllib2.urlopen(request)
    fl = o.read().strip()
    print '## cran'
    # <td><a href="TraMineR_1.8-8.tar.gz">TraMineR_1.8-8.tar.gz</a></td>
    hrefs = []
    soup = BeautifulSoup(fl)
    for link in soup.find_all('a'):
        l = link.get('href')
        if l <> '..':
            hrefs.append(link.get('href'))
    ppaths = []
    if len(pList) == 0: # all please
        ppaths = [os.path.join(mirror,x) for x in hrefs]
    else:
        for p in pList:
            res = [x for x in hrefs if (x.find(p) == 0) ]
            res = [x for x in res if len(x.split('_')[0]) == len(p)]
            if (len(res) > 0):
               firstone = res[0] 
               ppath = os.path.join(mirror,firstone)
               ppaths.append(ppath) # path containing archive
    for apath in ppaths: # check and snarf 
        dest = os.path.basename(apath)
        if os.path.exists(dest):
            print '### looks like %s already exists. Delete to redownload?' % dest
        else:
           print '### Cran res=',dest,'added',apath
           if get_archives:
               scl = ['wget',apath]
               retcode = subprocess.call(scl)
    hrefs = [os.path.join(mirror,x) for x in hrefs]
    return (hrefs,ppaths)

def main():
    argp=argparse.ArgumentParser()
    # try svn release tag from fhrc
    # currently 2.14
    argp.add_argument('--bioc_svn',default='https://hedgehog.fhcrc.org/bioconductor/branches/RELEASE_2_14/madman/Rpacks/')
    argp.add_argument('--cran',default='http://cran.rstudio.com/src/contrib/')
    argp.add_argument('--svntag',default='RELEASE_2_14')
    argp.add_argument('--packageList',default=default_packageList)
    argp.add_argument('otherargs', nargs=argparse.REMAINDER)
    args = argp.parse_args()
    cwD = os.getcwd()
    workdir = os.path.join(cwD,args.svntag)
    if not os.path.isdir(workdir):
        os.makedirs(workdir)
    os.chdir(workdir)
    pSplit = args.packageList.split(',')
    pList = [x.split('_')[0].strip() for x in pSplit]
    print '### pList=',pList
    (biochrefs,biocurls) = get_Bioc_urls(mirror = args.bioc_svn,pList=pList,get_archives=True)
    pList2 = list(set(pList) - set(biocurls)) # edgeRun eg
    (cranhrefs,cranurls) = get_CRAN_urls(args.cran,pList=pList2,get_archives=True) 
    allurls = biocurls + cranurls
    allhrefs = biochrefs+cranhrefs
    os.chdir(cwD)
    outf = open('%s.package_urls.txt' % args.svntag,'w')
    outf.write('\n'.join(allhrefs))
    outf.write('\n')
    outf.close()


if __name__ == "__main__":
    main()
