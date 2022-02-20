#!/usr/bin/env bash
# shellcheck disable=SC1091

# shellcheck disable=SC2128
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

# this script is run as root
# source environment variables
source '/tmp/provision/setup/environment'
source '/tmp/provision/setup_cms/envvars.sh'

# no dialogw or questions
export DEBIAN_FRONTEND=noninteractive

# fix the locales
locale-gen en_US.UTF-8 &>/dev/null
dpkg-reconfigure locales &>/dev/null
cp "$PROVISION_DIR/setup/environment" /etc/environment
echo "locales fixed"

timedatectl set-timezone "$TIMEZONE"
echo "system timezone set to 'Europe/Rome'"

# update & upgrade the system
quiet_update && quiet_upgrade
echo "system upgraded"

# base packages
quiet_install linux-virtual
echo "new kernels installed"

quiet_install htop moreutils tree lynx colordiff tmux git-core molly-guard \
              ntp ntp-doc ntpdate gpgv2 apt-transport-https \
              ca-certificates software-properties-common
echo "basic packages installed"

# quiet apt-get autoremove
quiet_autoremove

# ssh for root and CMS_USER
mkdir -p "$HOME/.ssh/"
cat "$PROVISION_DIR/setup/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

mkdir -p "$CMS_USER_HOME/.ssh/"
cat "$PROVISION_DIR/setup/id_rsa.pub" >> "$CMS_USER_HOME/.ssh/authorized_keys"
chmod 600 "$CMS_USER_HOME/.ssh/authorized_keys"
chown -R "$CMS_USER:$CMS_USER" "$CMS_USER_HOME/.ssh/"
echo "copied ssh key to $CMS_USER_HOME/.ssh/"

exit 0
