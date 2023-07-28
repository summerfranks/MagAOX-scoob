#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../_common.sh
set -euo pipefail

source /etc/os-release
if [[ $ID == ubuntu ]]; then
	sudo apt -y install nfs-kernel-server
else
	sudo yum -y install nfs-utils
fi

if [[ $MAGAOX_ROLE == RTC || $MAGAOX_ROLE == ICC ]]; then
	if [[ $ID == ubuntu ]]; then
		sudo systemctl enable nfs-kernel-server
		sudo systemctl start nfs-kernel-server
	else
		sudo systemctl enable nfs-server.service
		sudo systemctl start nfs-server.service
	fi
    cat <<'HERE' | sudo tee /etc/exports
/data/logs      aoc(ro,sync,all_squash)
/data/rawimages aoc(ro,sync,all_squash)
/data/telem     aoc(ro,sync,all_squash)
HERE
    sudo exportfs -a
fi
if [[ $MAGAOX_ROLE == AOC ]]; then
    for remote in rtc icc; do
        for path in /data/logs /data/rawimages /data/telem; do
            if ! grep -q "$remote:$path" /etc/fstab; then
                mountpoint="/data/$remote${path/\/data\///}"
                sudo mkdir -p $mountpoint
                echo "$remote:$path $mountpoint	nfs	defaults	0 0" | sudo tee -a /etc/fstab
                sudo mount $mountpoint || true
            fi
        done
    done
fi
