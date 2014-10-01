docker-nuodb
============

docker container for nuodb database

Usage
-----

To create the image kakawait/nuodb, execute the following command:

    docker build --rm -t kakawait/nuodb .

To run the image and bind to port 48004:

     docker run -d -p 48004:48004 kakawait/nuodb

The first time that you run your container, check the logs of the container by running:

    docker logs <CONTAINER_ID>

You will see an output like the following:

    ==========================================================================================
    You can now connect to this Nuodb Server:

        domain:
        [user] domain
        [password] bird

        database [testdb]:
        [user] dba
        [password] bird
        
        Hosts:
        [broker] localhost/127.0.0.1:48004 (DEFAULT_REGION)
        
        Database: testdb
        [SM] 87ff08502c9e/172.17.0.186:48005 (DEFAULT_REGION) [ pid = 290 ] RUNNING
        [TE] 87ff08502c9e/172.17.0.186:48006 (DEFAULT_REGION) [ pid = 352 ] RUNNING
    ==========================================================================================

Done!

Configuration
-------------

### Environment variables

- `BROKER` (default: `true`): Should this host be a broker?
- `DOMAIN_USER` (default: `domain`): The administrative user for your domain. All nodes should have the same user.
- `DOMAIN_PASSWORD` (default: `bird`): The administrative password for your domain. All nodes should have the same password. If you set value `**Random**` a random password will be generated.
- `DBA_USER` (default: `dba`): The administrative user for you database (see `DATABASE_NAME`).
- `DBA_PASSWORD` (default: `bird`): The administrative password for you database (see `DATABASE_NAME`). If you set value `**Random**` a random password will be generated.
- `DATABASE_NAME` (default: `testdb`): The database name of new database created when launching the container.
- `AUTOMATION` (default: `false`): Whether to enable automation on the system database. [NuoDB manual](http://dev.nuodb.com).
- `AUTOMATION_BOOTSTRAP` (default: `false`): Should this node bootstrap the system database? See [NuoDB manual](http://dev.nuodb.com).

### Override configuration

You could override nuodb `default.properties` by using mounting volume:

    docker run -d -p 48004:48004  -v <override-dir>:/nuodb-override kakawait/nuodb

where <override-dir> is an absolute path of a directory that could contain:

- `default.properties`: custom config file

Placeholder environment variable could be used inside your overrided `default.properties` like following:

    domainPassword = ${DOMAIN_PASSWORD}

Thus `domainPassword` will be equals to value of environment variable `$DOMAIN_PASSWORD`

### Mounting the database file volume

In order to persist the database data, you can mount a local folder from the host on the container to store the database files. To do so:

    docker run -d -p 48004:48004 -v /path/in/host:/opt/nuodb/data kakawait/nuodb