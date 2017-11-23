#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source '/tmp/provision/setup_cms/envvars.sh'

cp "$PROVISION_DIR/utils/systemd/cms/cms.service" '/etc/systemd/system/'
echo "copied systemd service scripts"

mkdir -p '/usr/share/cms/'
cp "$PROVISION_DIR/utils/systemd/cms/"cms_service*.sh '/usr/share/cms/'
echo "copied scripts in '/usr/share/cms/'"

systemctl enable cms.service
echo "systemd CMS service enabled"
