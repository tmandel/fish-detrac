#!/bin/bash


if [[ $# -lt 1 ]]
then
    echo "Usage: $0 condaPath"
    exit 2
fi

CONDA_BASE=$1

cd fishtrac/trackers/D3S
D3SPATH=$PWD
git clone https://github.com/tmandel/d3s_repo
cd d3s_repo
touch __init__.py
cp pytracking/tracker/segm/segm.py . 
cp pytracking/tracker/segm/optim.py . 
patch -R -p0 < $D3SPATH/segmdiff.patch
cd $D3SPATH
sed -i "s|params.segm_net_path =.*|params.segm_net_path = '$D3SPATH/network/SegmNet.pth.tar'|" d3s_repo/pytracking/parameter/segm/default_params.py
mkdir network
cd network 
wget http://data.vicos.si/alanl/d3s/SegmNet.pth.tar
cd $D3SPATH
cd d3s_repo
$CONDA_BASE/DAN/bin/python -c "from pytracking.evaluation.environment import create_default_local_file; create_default_local_file()"
$CONDA_BASE/DAN/bin/python -c "from ltr.admin.environment import create_default_local_file; create_default_local_file()"
rm -rf .git
rm .gitignore
rm install*

