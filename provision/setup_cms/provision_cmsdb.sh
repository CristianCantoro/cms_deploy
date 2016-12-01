#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source '/tmp/provision/setup_cms/envvars.sh'

CMS_DBCONNECTION=$(grep '"database": ' "$CMS_BASEDIR/config/cms.conf" | \
  sed 's/\s*"database":\s*//g' | tr -d '",')

# postgresql+psycopg2://cmsuser:dbpass@localhost/cmsdb
CMS_DBUSER=$(echo "$CMS_DBCONNECTION" | \
  sed  -r 's#[^/]+//([^:]+):([^@]+)@([^/]+)/(.+)#\1#g')
CMS_DBPASS=$(echo "$CMS_DBCONNECTION" | \
  sed  -r 's#[^/]+//([^:]+):([^@]+)@([^/]+)/(.+)#\2#g')
CMS_DBHOST=$(echo "$CMS_DBCONNECTION" | \
  sed  -r 's#[^/]+//([^:]+):([^@]+)@([^/]+)/(.+)#\3#g')
CMS_DB=$(echo "$CMS_DBCONNECTION" | \
  sed  -r 's#[^/]+//([^:]+):([^@]+)@([^/]+)/(.+)#\4#g')

echo "---"
echo "CMS DB vars:" 
echo "- CMS_DB: $CMS_DB" 
echo "- CMS_DBUSER: $CMS_DBUSER"
echo "- CMS_DBHOST: $CMS_DBHOST"
echo "--------"

# move postgres data dir to CMS datadir
service postgresql stop

mkdir -p "$CMS_DATADIR/postgresql"
rsync -Caz '/var/lib/postgresql/' "$CMS_DATADIR/postgresql"
echo "created postgres data dir '$CMS_DATADIR/postgresql'"

chown -R 'postgres:postgres' "$CMS_DATADIR/postgresql"
chmod -R 0700 "$CMS_DATADIR/postgresql/9.3/main"

cp "$PROVISION_DIR/postgresql/postgresql.conf" \
  '/etc/postgresql/9.3/main/postgresql.conf'
rm -rf '/var/lib/postgresql'
[[ ! -L '/var/lib/postgresql' ]] && \
  ln -s "$CMS_DATADIR/postgresql" '/var/lib/postgresql'

service postgresql start

# copy .pgpass
cp "$PROVISION_DIR/postgresql/.pgpass"  "$CMS_USER_HOME"
chmod 600 "$PROVISION_DIR/postgresql/.pgpass"
chown "$CMS_USER:$CMS_USER" "$PROVISION_DIR/postgresql/.pgpass"
echo ".pgpass file copied"

echo -n "create CMS DB user '$CMS_DBUSER': "
if ! su -c "psql postgres -tAc \
        \"SELECT 1 FROM pg_roles WHERE rolname='$CMS_DBUSER'\" | \
        grep -q 1" postgres; then
  su -c "createuser $CMS_DBUSER -w" postgres
  echo "CMS DB user '$CMS_DBUSER' created"
else
  echo "skipping creation of db user '$CMS_DBUSER', already exists"
fi

echo -n "create CMS DB '$CMS_DB': "
if ! su -c "psql postgres -tAc \
        \"SELECT 1 FROM pg_catalog.pg_database WHERE datname='$CMS_DB'\" | \
        grep -q 1" postgres; then
  su -c "createdb -O $CMS_DBUSER $CMS_DB" postgres
  echo "CMS DB '$CMS_DB' created"
else
  echo "skipping creation of db '$CMS_DB', already exists"
fi

echo -n "ALTER SCHEMA public OWNER TO $CMS_DBUSER: "
su -c "psql $CMS_DB -c \
        \"ALTER SCHEMA public OWNER TO $CMS_DBUSER\"" postgres

echo -n "GRANT SELECT ON pg_largeobject TO $CMS_DBUSER: "
su -c "psql $CMS_DB -c \
        \"GRANT SELECT ON pg_largeobject TO $CMS_DBUSER\"" postgres

echo -n "Set new password for CMS DB user '$CMS_DBUSER': "
su -c "psql $CMS_DB -c \
        \"ALTER USER \"$CMS_DBUSER\" WITH PASSWORD '$CMS_DBPASS'\"" postgres

# init CMS db
echo "run cmsInitDB"
cmsInitDB

echo "-----------------"
echo "That's all folks!"

exit 0
