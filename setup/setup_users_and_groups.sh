#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -e /usr/bin/sudo ]]; then
  _REAL_SUDO=/usr/bin/sudo
elif [[ -e /bin/sudo ]]; then
  _REAL_SUDO=/bin/sudo
else
  if [[ -z $(command -v sudo) ]]; then
    echo "Install sudo before provisioning"
  else
    _REAL_SUDO=$(which sudo)
  fi
fi
source $DIR/_common.sh
source /etc/os-release

if [[ $ID == ubuntu ]]; then
	$_REAL_SUDO groupadd magaox
	$_REAL_SUDO groupadd magaox-dev
else
	creategroup magaox
	creategroup magaox-dev
fi

if [[ $MAGAOX_ROLE != vm ]]; then
  if [[ $ID == ubuntu ]]; then
	$_REAL_SUDO useradd -G sudo,guestobs xsup
	luseradd -g guestobs guestobs
	$_REAL_SUDO mkdir /home/xsup
	$_REAL_SUDO mkdir /home/guestobs
	$_REAL_SUDO mkdir /data/users/guestobs
	$_REAL_SUDO chown -R xsup:xsup /home/xsup
	$_REAL_SUDO chown -R guestobs:guestobs /home/guestobs
  else
	createuserxsup
	createuser guestobs
  fi
  sudo passwd --lock guestobs  # SSH login still possible
  if [[ $ID == ubuntu ]]; then
    $_REAL_SUDO groupadd guestobs
  else
	creategroup guestobs
  fi
  sudo gpasswd -d guestobs magaox || true  # prevent access for shenanigans
  sudo gpasswd -a guestobs guestobs || true
  sudo chown guestobs:guestobs /data/users/guestobs
  sudo chmod g+rwX /data/users/guestobs
  if [[ -z $(groups | tr ' ' '\n' | grep 'guestobs$') ]]; then
    sudo gpasswd -a xsup guestobs
    log_success "Added xsup to group guestobs"
  else
    log_warning "Cannot add xsup to group guestobs"
  fi

  if sudo test ! -e /home/xsup/.ssh/id_ed25519; then
    $_REAL_SUDO -u xsup ssh-keygen -t ed25519 -N "" -f /home/xsup/.ssh/id_ed25519 -q
  else
    log_warning "Cannot generate xsup key"
  fi
  if ! grep -q magaox-dev /etc/pam.d/su; then
    cat <<'HERE' | sudo sed -i '/pam_rootok.so$/r /dev/stdin' /etc/pam.d/su
auth            [success=ignore default=1] pam_succeed_if.so user = xsup
auth            sufficient      pam_succeed_if.so use_uid user ingroup magaox-dev
HERE
    log_info "Modified /etc/pam.d/su"
  else
    log_info "/etc/pam.d/su already includes reference to magaox-dev, not modifying"
  fi
fi
if [[ $EUID != 0 ]]; then
  if [[ -z $(groups | tr ' ' '\n' | grep 'magaox-dev$') ]]; then
    sudo gpasswd -a $USER magaox-dev
    log_success "Added $USER to group magaox-dev"
    log_warn "Note: You will need to log out and back in before this group takes effect"
  fi
  if [[ -z $(groups | tr ' ' '\n' | grep 'magaox$') ]]; then
    sudo gpasswd -a $USER magaox
    log_success "Added $USER to group magaox"
    log_warn "Note: You will need to log out and back in before this group takes effect"
  fi
fi
