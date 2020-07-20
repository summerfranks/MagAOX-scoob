#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../_common.sh
set -euo pipefail
if [[ $MAGAOX_ROLE == AOC || $MAGAOX_ROLE == vm || $MAGAOX_ROLE == ci ]]; then
    SUP_COMMIT_ISH=master
    orgname=magao-x
    reponame=sup
    parentdir=/opt/MagAOX/source
    clone_or_update_and_cd $orgname $reponame $parentdir
    git checkout $SUP_COMMIT_ISH

    for envname in py37 dev; do
        set +u; conda activate $envname; set -u
        cd $parentdir/$reponame
        conda install -y nodejs yarn
        make  # installs Python module in editable mode, builds all js
        cd
        python -c 'import sup'  # verify sup is on PYTHONPATH
    done
    UNIT_PATH=/etc/systemd/system/
    if [[ ! -e $UNIT_PATH/sup.service ]]; then
        sudo cp /opt/MagAOX/config/sup.service $UNIT_PATH/sup.service
        OVERRIDE_PATH=$UNIT_PATH/sup.service.d/
        sudo mkdir -p $OVERRIDE_PATH
        echo "[Service]" | sudo tee $OVERRIDE_PATH/override.conf
        echo "Environment=\"MAGAOX_ROLE=$MAGAOX_ROLE\"" | sudo tee -a $OVERRIDE_PATH/override.conf
    fi
    sudo systemctl enable sup.service || true
    sudo systemctl restart sup.service || true
fi