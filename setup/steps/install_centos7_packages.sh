#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../_common.sh
set -euo pipefail

# needed for (at least) git:
yum groupinstall -y 'Development Tools'

# Install EPEL
# use || true so it's not an error if already installed:
yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true

# changes the set of available packages, making devtoolset-7 available
yum -y install centos-release-scl

# Install build tools and utilities
yum install -y \
    openssh \
    cmake3 \
    vim \
    nano \
    wget \
    mlocate \
    htop \
    ntp \
    zlib-devel \
    libudev-devel \
    ncurses-devel \
    nmap-ncat \
    lm_sensors \
    hddtemp \
    readline-devel \
    pkgconfig \
    bison \
    flex \
    dialog \
    autossh \
    check-devel \
    subunit-devel \
    pciutils \
    libusb-devel \
    usbutils \
    tmux \
    boost-devel \
    gsl \
    gsl-devel \
    bc \
    log4cxx-devel \
;

sudo alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
    --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
    --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
    --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
    --family cmake

yum-config-manager --add-repo https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/CentOS_7/network:messaging:zeromq:release-stable.repo
yum install -y zeromq-devel

# For some reason, pkg-config doesn't automatically look here?
echo "export PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" > /etc/profile.d/pkg-config-path.sh