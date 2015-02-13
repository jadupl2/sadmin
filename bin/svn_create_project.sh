set -x 
PROJECT=$1                              ; export PROJECT
export BASE_DIR="/svn/sadmin"           ; export BASE_DIR

cd $BASE_DIR
mkdir tmpdir
cd tmpdir
mkdir trunk
mkdir branches
mkdir tags

svn import . file:///${BASE_DIR}/${PROJECT} --message 'Initial repository structure'

cd ..
rm -rf tmpdir

svn list --verbose file:///${BASE_DIR}/${PROJECT}
