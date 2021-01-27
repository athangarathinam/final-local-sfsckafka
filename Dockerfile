# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.3.1

#ENV GETUPD=y

#install vim and update 
#RUN dpkg -i debian-archive-keyring_2017.5~deb8u1_all.deb -y \
RUN sed -i 's;http://archive.debian.org/debian/;http://deb.debian.org/debian/;' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install unzip \
    && apt-get install zip \
    && apt-get --yes --force-yes install -y --no-install-recommends apt-utils \
    vim
        
# Copy config and certs
COPY .build/certs/*.crt /usr/local/share/ca-certificates/
COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties

RUN update-ca-certificates

# Create plugin directory
RUN mkdir -p /usr/share/java/plugins
RUN mkdir -p /usr/share/java/kafka-connect-jdbc
RUN mkdir -p /etc/kafka/kafka-logs

# Confluent Hub Config and Installs
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1 \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.0.1




#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors ; 'bash'

