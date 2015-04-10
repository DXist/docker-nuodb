#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Disable Linux Transparent Huge Pages or nuodb won't start
# need --privileged=true :'(
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

DEFAULT_ROUTE=$(/sbin/ip route | awk '/default/ { print $3 }')
IP=$(/sbin/ip address |awk '/global eth0/ { split($2, array, "/") } END {print array[1]}')

if [ "${BROKER_ALT_ADDR}" = "self" ]; then
	export BROKER_ALT_ADDR=${IP}
fi

export BROKER_ALT_ADDR=${BROKER_ALT_ADDR:-$DEFAULT_ROUTE}

if [ "${PEER}" = "self" ]; then
	export PEER=${BROKER_ALT_ADDR}
fi

start_nuoagent() {
    sudo -u nuodb /bin/bash -c "SHELL=/bin/bash NUODB_USER=nuodb java -jar /opt/nuodb/jar/nuoagent.jar --broker > /dev/null 2>&1 &"
    STATUS=1
    while [[ STATUS -ne 0 ]]; do
        echo "=> Waiting for nuoagent service startup"
        sleep 2
        /opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain hosts"
        STATUS=$?
    done
    echo "=> Nuoagent started"
}

stop_nuoagent() {
    PID=$(ps -ef | grep "nuoagent" | grep -v grep| awk '{print $2}')
    if [ -n "$PID" ]; then
        kill -9 $PID &>/dev/null
    fi
    echo "=> Nuoagent stopped"
}

if [ "$DOMAIN_PASSWORD" = "**Random**" ]; then
    unset DOMAIN_PASSWORD
    RAND_DOMAIN_PASSWORD=$(pwgen -s 12 1)
fi

if [ "$DBA_PASSWORD" = "**Random**" ]; then
    unset DBA_PASSWORD
    RAND_DBA_PASSWORD=$(pwgen -s 12 1)
fi

if [ -f /nuodb-override/default.properties ]; then
    cp /nuodb-override/default.properties /opt/nuodb/etc/default.properties.tpl
fi
rm -f /opt/nuodb/etc/default.properties
envsubst < "/opt/nuodb/etc/default.properties.tpl" > "/opt/nuodb/etc/default.properties"
chown nuodb:nuodb /opt/nuodb/etc/default.properties
envsubst < '/etc/supervisor/conf.d/supervisord.conf.tpl' > '/etc/supervisor/conf.d/supervisord.conf';

start_nuoagent

echo "=> Starting configuration"
echo -e "\t=> Create sm process from database $DATABASE_NAME"
INIT_ARCHIVE=true
if [ -f /opt/nuodb/data/$DATABASE_NAME/.init ]; then
    INIT_ARCHIVE=false
fi
/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "start process sm host $BROKER_ALT_ADDR database $DATABASE_NAME archive /opt/nuodb/data/$DATABASE_NAME initialize $INIT_ARCHIVE" &>/dev/null
touch /opt/nuodb/data/$DATABASE_NAME/.init
echo -e "\t=> Create te process from database $DATABASE_NAME"
/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "start process te host $BROKER_ALT_ADDR database $DATABASE_NAME options '--dba-user $DBA_USER --dba-password ${DBA_PASSWORD:-$RAND_DBA_PASSWORD} --verbose info,warn,error'" &>/dev/null

if [ -n "$LICENSE" ]; then
    echo -e "\t=> Install nuodb license"
    echo $LICENSE > /license.file
    /opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "apply domain license licenseFile /license.file" &>/dev/null
fi

SUMMARY=$(/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain summary")

stop_nuoagent
echo "=> Done!"

echo ""
echo "=========================================================================================="
echo "You can now connect to this Nuodb Server:"
echo ""
echo "    domain:"
echo "    [user] $DOMAIN_USER"
echo "    [password] ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD}"
echo ""
echo "    database [$DATABASE_NAME]:"
echo "    [user] $DBA_USER"
echo "    [password] ${DBA_PASSWORD:-$RAND_DBA_PASSWORD}"
while IFS= read -r line
do
    echo  "    $line"
done <<< "$SUMMARY"
echo ""
echo "    ecosystem:"
if [ "$NUORESTSVC" = true ]; then
    echo "    [autoconsole] localhost:8888"
    echo "    [autoconsole-admin] localhost:8889"
fi
if [ "$NUOWEBCONSOLE" = true ]; then
    echo "    [web console] localhost:9001"
fi
echo "=========================================================================================="
echo ""

supervisord -n -e $LOG_LEVEL -c /etc/supervisor/conf.d/supervisord.conf
