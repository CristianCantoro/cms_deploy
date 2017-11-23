#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source '/tmp/provision/setup_cms/envvars.sh'

CMS_LOGDIR="/var/log/cms"

##############################################################################
checksum() {

  local hashsum_file="$1"
  local checksum_algo='md5sum'

  echo -n "checking checksum of file $hashsum_file "
  case "$hashsum_file" in
    *'sha1'*)
      echo -n "(sha1sum): "
      checksum_algo='sha1sum'
      ;;
    *'sha224'*)
      echo -n "(sha224sum):"
      checksum_algo='sha224sum'      
      ;;
    *'sha256'*)
      echo -n "(sha256sum):"
      checksum_algo='sha256sum'
      ;;
    *'sha384'*)
      echo -n "(sha384sum):"
      checksum_algo='sha384sum'
      ;;
    *'sha512'*)
      echo -n "(sha512sum):"
      checksum_algo='sha512sum'
      ;;
    *'md5'*)
      echo -n "(md5sum):"
      checksum_algo='md5sum'
      ;;
    *)
      (>&2 echo "Unrecognized hashsum file")
      (>&2 echo "Valid names must contain either "\
                "md5 or sha{1, 224, 256, 384, 512}")
      exit 1
      ;;
  esac

  "$checksum_algo" -c "$hashsum_file"
}
##############################################################################

quiet_upgrade
echo "upgrades installed"

# Install CMS dependencies
# (see: https://cms.readthedocs.io/en/v1.3/Installation.html)
quiet_install build-essential openjdk-8-jre openjdk-8-jdk fpc \
    postgresql postgresql-client gettext python2.7 \
    iso-codes shared-mime-info stl-manual cgroup-lite
echo "core dependencies installed"

# Only if you are going to use pip/virtualenv to install python dependencies
quiet_install python-dev libpq-dev libcups2-dev libyaml-dev \
    libffi-dev python-pip
echo "libraries installed"

quiet_install python-setuptools python-tornado python-psycopg2 \
     python-sqlalchemy python-psutil python-netifaces python-crypto \
     python-tz python-six python-beautifulsoup python-mechanize \
     python-coverage python-mock python-requests python-werkzeug \
     python-gevent python-bcrypt python-chardet patool \
     python-yaml python-sphinx python-cups python-pypdf2
echo "python dependencies installed"

# separate the installtion of nginx from the rest
quiet_install nginx-full
echo "nginx installed"

# Optional
quiet_install php7.0-cli php7.0-fpm phppgadmin texlive-latex-base a2ps \
    gcj-jdk haskell-platform
echo "additional packages installed"

if $CMS_INSTALL_TEXLIVEFULL; then
  echo "installing package texlive-full, this could take a long time..."
  quiet_install texlive-full
  echo "texlive-full package installed"
else
  echo "skipping installation of texlive-full"
fi

# auto-clean
apt-get -qq -y autoremove &>/dev/null
echo "clean system (apt-get autoremove)"

# clean up builds (just in case)
cd "$CMS_BASEDIR" && rm -rf 'cms.egg-info/' && rm -rf 'build/'
echo "cleanup build"

# CMS base install
rsync "$PROVISION_DIR/cms/$CMS_INSTALL_FILE" "$CMS_USER_HOME/"
rsync "$PROVISION_DIR/cms/$CMS_HASHSUM_FILE" "$CMS_USER_HOME/"

# check checksum
cd "$CMS_USER_HOME/" && checksum "$CMS_HASHSUM_FILE"

# extract files
cd "$CMS_USER_HOME/" && tar xzf "$CMS_INSTALL_FILE"

# override CMS files and configurations specified in 'provision/cms/override'
rsync -r "$PROVISION_DIR/cms/override/" "$CMS_BASEDIR"

# install cms
cd "$CMS_BASEDIR" && ./setup.py build
echo "CMS built"

cd "$CMS_BASEDIR" && ./setup.py install
echo "CMS installed"

cd "$CMS_BASEDIR" && cp 'config/cms.conf' '/usr/local/etc/'
cd "$CMS_BASEDIR" && cp 'config/cms.ranking.conf' '/usr/local/etc/'
cd "$CMS_BASEDIR"
echo "CMS configuration files installed"

# add group cmsuser
groupadd "$CMS_USERGROUP"
echo "create CMS user group '$CMS_USERGROUP'"

# add user to cmsuser group
usermod -a -G "$CMS_USERGROUP" "$CMS_USER"
echo "add user '$CMS_USER' to CMS user group '$CMS_USERGROUP'"

# create basedir
mkdir -p "$CMS_BASEDIR"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_BASEDIR"
echo "created CMS base dir"

# add data dir
mkdir -p "$CMS_DATADIR"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR"
echo "created CMS data dir"

# add tmp dir in datadir
mkdir -p "$CMS_DATADIR/tmp"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR/tmp"
echo "created tmp dir for CMS in datadir"

cp -r "$PROVISION_DIR/cms/scripts" "$CMS_USER_HOME/.scripts"
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_USER_HOME/.scripts"
cp "$PROVISION_DIR/cms/scripts/contest_id" "$CMS_USER_HOME/contest_id"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_USER_HOME/contest_id"
echo "copied scripts dir in '$CMS_USER_HOME'"

# /var/local/cache/cms -> /data/cache/cms
mkdir -p "$CMS_DATADIR/cache/cms"
if [ -d '/var/local/cache/cms/' ]; then
  rsync -Caz '/var/local/cache/cms/' "$CMS_DATADIR/cache/cms"
else
  mkdir -p '/var/local/cache/cms/'
fi
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR/cache"
chmod -R g+rwx "$CMS_DATADIR/cache/cms"
echo "created cache dir for CMS in datadir"

rm -rf '/var/local/cache/cms'
[[ ! -L '/var/local/cache/cms' ]] && \
  ln -s "$CMS_DATADIR/cache/cms" '/var/local/cache/cms'
echo "linked cache dir from '/var/local/cache/cms' to" \
     "'$CMS_DATADIR/cache/cms'"

# create log dir in
mkdir -p "$CMS_LOGDIR"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_LOGDIR"

# copy pandoc dir
rsync -Cavz "$PROVISION_DIR/pandoc" "$CMS_DATADIR"
cp -a "$PROVISION_DIR/pandoc/template.tex" "$CMS_DATADIR"

exit 0
