#!/usr/bin/env bash
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

# shellcheck disable=SC1091
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

# add repository to install older version of postgres
# (see: https://www.postgresql.org/download/linux/ubuntu/)
#
# Create the file repository configuration
echo "Add postgresql repository"
echo "deb http://apt.postgresql.org/pub/repos/apt " \
     "$(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Import the repository signing key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  apt-key add --no-tty - &>/dev/null
echo "postgres repository added"

# Run apt-update to update the package lists
quiet_update

# Install the database and db client
quiet_install "postgresql-${CMS_DB_VERSION}" \
              "postgresql-client-${CMS_DB_VERSION}"
echo "database installed"

# Install CMS dependencies
# (see: https://cms.readthedocs.io/en/v1.4/Installation.html)
quiet_install build-essential openjdk-8-jdk-headless fp-compiler python3.6 \
    cppreference-doc-en-html cgroup-lite libcap-dev zip
echo "core dependencies installed"

# Only if you are going to use pip/virtualenv to install python dependencies
quiet_install python3.6-dev libpq-dev libcups2-dev libyaml-dev \
    libffi-dev python3-pip
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
# note: package gcj-jdk has no installation candidate on Ubuntu 18.04.5
quiet_install  python2.7 php7.2-cli php7.2-fpm phppgadmin \
    texlive-latex-base texlive-xetex texlive-fonts-recommended \
    a2ps haskell-platform rustc mono-mcs
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

# create basedir
mkdir -p "$CMS_BASEDIR"
echo "created CMS base dir"

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
cd "$CMS_USER_HOME/" && chown -R "$CMS_USER:$CMS_USER" "$CMS_BASEDIR"

# override CMS files and configurations specified in 'provision/cms/override'
rsync -r "$PROVISION_DIR/cms/override/" "$CMS_BASEDIR"
echo "copy override files"

# substitute all the instances of "cmsuser" in prerequisites.py with the
# value of $CMS_USER
echo "substitute '$CMS_USER' for 'cmsuser' in prerequisites.py"
cd "$CMS_BASEDIR" && \
   sed -i "s/\"cmsuser\"/\"$CMS_USER\"/g" prerequisites.py

# add the group $CMS_USERGROUP, fail graciously if the group already exists
echo "add '$CMS_USERGROUP' group"
addgroup "$CMS_USERGROUP" || true

# add user to CMS user group
echo "add user '$CMS_USER' to CMS user group '$CMS_USERGROUP'"
usermod -a -G "$CMS_USERGROUP" "$CMS_USER"

# change group ownership of $CMS_USER_HOME to $CMS_USERGROUP (which may be
# different from the default)
echo "change group ownership of $CMS_USER_HOME to $CMS_USERGROUP"
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_USER_HOME"

# install
cd "$CMS_BASEDIR" && pip3 install -r requirements.txt
echo "requirements installed"

# run CMS prerequisites file
echo "build everything (as $CMS_USER)"
cd "$CMS_BASEDIR" && su -c "python3 prerequisites.py build_isolate" "$CMS_USER"
cd "$CMS_BASEDIR" && su -c "python3 prerequisites.py build" "$CMS_USER"
echo "built done"

echo "install everything"
cd "$CMS_BASEDIR" && python3 prerequisites.py -y install
echo "CMS prerequisites script run"

# install cms
cd "$CMS_BASEDIR" && python3 setup.py build
echo "CMS built"

cd "$CMS_BASEDIR" && python3 setup.py install
echo "CMS installed"

# cms.conf
cd "$CMS_BASEDIR" && cp 'config/cms.conf' '/usr/local/etc/'
chown "$CMS_USER:$CMS_USERGROUP" '/usr/local/etc/cms.conf'
# cms.ranking.conf
cd "$CMS_BASEDIR" && cp 'config/cms.ranking.conf' '/usr/local/etc/'
chown "$CMS_USER:$CMS_USERGROUP" '/usr/local/etc/cms.ranking.conf'
# isolate
chown "$CMS_USER:$CMS_USERGROUP" '/usr/local/etc/isolate'
echo "CMS configuration files installed"

# change owner of basedir
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_BASEDIR"
echo "changed owner of CMS base dir $CMS_BASEDIR to $CMS_USER"

# add data dir
mkdir -p "$CMS_DATADIR"
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR"
echo "created CMS data dir"

# add tmp dir in datadir
mkdir -p "$CMS_DATADIR/tmp"
chown "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR/tmp"
echo "created tmp dir for CMS in datadir"

cp -r "$PROVISION_DIR/utils/scripts" "$CMS_USER_HOME/.scripts"
chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_USER_HOME/.scripts"
mv "$CMS_USER_HOME/.scripts/contest_id" "$CMS_USER_HOME/contest_id"
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
echo "created '$CMS_LOGDIR'"

# copy pandoc dir
rsync -Cavz "$PROVISION_DIR/pandoc" "$CMS_DATADIR"
cp -a "$PROVISION_DIR/pandoc/template.tex" "$CMS_DATADIR"
chown "$CMS_USER:$CMS_USERGROUP" "$PROVISION_DIR/pandoc"
echo "copied pandoc files"

if [ -d "$WORK_DIR" ]; then
  rsync -Cavz "$WORK_DIR" "$CMS_DATADIR"
  chown -R "$CMS_USER:$CMS_USERGROUP" "$CMS_DATADIR"
  echo "copied word dir in '$CMS_DATADIR'"
fi

exit 0
