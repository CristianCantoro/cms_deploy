#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source '/tmp/provision/setup_cms/envvars.sh'

CMS_NGINXDIR="$CMS_DATADIR/nginx"

# crate nginx dir in data dir
mkdir -p "$CMS_NGINXDIR"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_NGINXDIR"
echo "created CMS data dir"

cp "$PROVISION_DIR/nginx/nginx_cms.conf" "$CMS_NGINXDIR/nginx_cms.conf"

[[ ! -L '/etc/nginx/sites-available/nginx_cms.conf' ]] && \
  ln -s "$CMS_NGINXDIR/nginx_cms.conf" \
    '/etc/nginx/sites-available/nginx_cms.conf'

[[ ! -L '/etc/nginx/sites-enabled/nginx_cms.conf' ]] && \
  cd '/etc/nginx/sites-enabled' && \
    ln -s '../sites-available/nginx_cms.conf' '.'

[[ -L '/etc/nginx/sites-enabled/default' ]] && \
  unlink '/etc/nginx/sites-enabled/default'

mkdir -p "$CMS_DATADIR/log/nginx/"
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR/log"
chown 'www-data:adm' "$CMS_DATADIR/log/nginx/"

$(which nginx) -t
service nginx restart

exit 0
