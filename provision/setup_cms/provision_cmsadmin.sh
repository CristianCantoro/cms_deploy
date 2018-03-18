#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
source '/tmp/provision/setup_cms/envvars.sh'

# Install CMS dependencies
# add CMS admin user
su -c "cmsAddAdmin -p $CMS_ADMIN_PASSWORD $CMS_ADMIN_USER" "$CMS_USER"

exit 0
