FROM java:7u75
MAINTAINER kakawait <thibaud.lepretre@gmail.com>

### Install dependencies ###
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -yq install pwgen supervisor gettext-base sudo && \
  rm -rf /var/lib/apt/lists/*

### Install nuodb ###
RUN wget -q -O /tmp/nuodb_2.2.0.10_amd64.deb "http://download.nuohub.org/nuodb_2.2.0.10_amd64.deb" && \
    dpkg --install /tmp/nuodb_2.2.0.10_amd64.deb && \
    rm /tmp/nuodb_2.2.0.10_amd64.deb

### Setup ###
# Mount volume
RUN mkdir -p /opt/nuodb/data && \
    mkdir -p /nuodb-override && \
    chown nuodb:nuodb /opt/nuodb/data
VOLUME ["/opt/nuodb/data", "/nuodb-override"]
RUN chown nuodb:nuodb /opt/nuodb/data

# Add files
ADD run.sh /run.sh
RUN chmod +x /run.sh
ADD start_db.sh /start_db.sh
RUN chmod +x /start_db.sh

ADD default.properties.tpl /opt/nuodb/etc/default.properties.tpl
ADD supervisord.conf.tpl /etc/supervisor/conf.d/supervisord.conf.tpl

### Environment variables ###
ENV NUODB_HOME /opt/nuodb
ENV BROKER true
ENV DOMAIN_USER domain
ENV DOMAIN_PASSWORD bird
ENV DBA_USER dba
ENV DBA_PASSWORD bird
ENV PEER self

ENV NEW_PROCESS_PORT_RANGE 48005

ENV DATABASE_NAME testdb

ENV AUTOMATION false
ENV AUTOMATION_BOOTSTRAP false

ENV SUPERVISOR_LOG_LEVEL INFO
ENV LOG_LEVEL INFO

ENV NUOAGENT true
ENV NUOWEBCONSOLE true
ENV NUORESTSVC true

# Define working directory.
WORKDIR /opt/nuodb

CMD /run.sh
