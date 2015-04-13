#!/bin/bash

echo "=> Starting db configuration"
echo -e "\t=> Create sm process from database $DATABASE_NAME"
INIT_ARCHIVE=true
if [ -f /opt/nuodb/data/$DATABASE_NAME/.init ]; then
    INIT_ARCHIVE=false
fi
/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "start process sm host $BROKER_ALT_ADDR database $DATABASE_NAME archive /opt/nuodb/data/$DATABASE_NAME initialize $INIT_ARCHIVE"
touch /opt/nuodb/data/$DATABASE_NAME/.init
echo -e "\t=> Create te process from database $DATABASE_NAME"
/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "start process te host $BROKER_ALT_ADDR database $DATABASE_NAME options '--dba-user $DBA_USER --dba-password ${DBA_PASSWORD:-$RAND_DBA_PASSWORD} --verbose info,warn,error'"
