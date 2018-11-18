#!/usr/bin/env bash
set -eu
IFS=$'\n\t'

# Parse YAML file to bash variables
#
# Usage:
#   eval "$(parse_yaml <yml_file> <prefix>)"
#
# Taken from: 
# https://gist.github.com/pkuczynski/8665367
function parse_yaml() {
   local prefix="$2"
   local s
   s='[[:space:]]*'
   local w
   w='[a-zA-Z0-9_]*'
   local fs
   fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  "$1" |
   awk -F"$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'"$prefix"'",vn, $2, $3);
      }
   }'
}

##############################################################################
### CONFIG VARIABLES
#
## CMS variables
# CMS_VERSION='1.2.0'
# CMS_INSTALL_FILE='cms_v1.2.0.tar.gz'
# CMS_HASHSUM_FILE='cms_v1.2.0.tar.gz.sha256sum'
# CMS_USER='vagrant'
# CMS_USERGROUP='cmsuser'
#
## CMS directory
# CMS_USER_HOME="/home/$CMS_USER"
# CMS_BASEDIR="$CMS_USER_HOME/cms"
# CMS_DATADIR='/data'
#
# # provision directory
# PROVISION_DIR='/tmp/provision'

# Read YAML config file

envars_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISION_DIR="$(dirname "${envars_path}")"
WORK_DIR="$(realpath "$(dirname "${envars_path}")/../work")"

eval "$(parse_yaml "${envars_path}/../cms.yml" '')"

unset envars_path

##############################################################################


echo "Env vars"
echo "--------"
echo "CMS env vars:"
echo "- CMS_VERSION: $CMS_VERSION"
echo "- CMS_INSTALL_FILE (HASHSUM): $CMS_INSTALL_FILE ($CMS_HASHSUM_FILE)"
echo "- CMS_USER: $CMS_USER"
echo "- CMS_USER_HOME: $CMS_USER_HOME"
echo "- CMS_BASEDIR: $CMS_BASEDIR"
echo "- CMS_DATADIR: $CMS_DATADIR"
echo "- CMS_USERGROUP: $CMS_USERGROUP"
echo "- CMS_ADMIN_USER: $CMS_ADMIN_USER"
echo "- CMS_ADMIN_PASSWORD: $CMS_ADMIN_PASSWORD"
echo "---"
echo "Provision vars"
echo "- PROVISION_DIR: $PROVISION_DIR"
echo "- WORK_DIR: $WORK_DIR"
echo "--------"

# no dialog or questions
export DEBIAN_FRONTEND=noninteractive
echo "set DEBIAN_FRONTEND to 'noninteractive'"

# source functions for quiet apt update/uograde/install
source "$PROVISION_DIR/setup/quiet_apt.sh"
