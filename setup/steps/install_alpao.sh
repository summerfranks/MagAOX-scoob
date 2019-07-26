#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../_common.sh
set -euo pipefail
cd alpao
patch -Np1 < alpao_build_fix.patch || true
# option 2 - "Install ASDK and Interface Corp. PEX-292144 support"
echo 2 | sudo bash Linux/InstallASDK.sh
