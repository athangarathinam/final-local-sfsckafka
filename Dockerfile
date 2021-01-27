# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.3.1

#ENV GETUPD=y

ENV kafka_addon_name=${KAFKA_ADDON:-KAFKA}
ENV prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
ENV kafka_prefix=$(echo $prefix_env_var)
ENV kafka_url_env_var="$(echo $kafka_addon_name)_URL"
ENV postgres_addon_name=${POSTGRES_ADDON:-DATABASE}

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
ENV CONNECT_REST_PORT=$PORT

ENV bootstrap.servers=${!kafka_url_env_var//kafka+ssl:\/\//}
ENV group.id=$(echo $kafka_prefix)connect-cluster

ENV key.converter=org.apache.kafka.connect.json.JsonConverter
ENV value.converter=org.apache.kafka.connect.json.JsonConverter
ENV key.converter.schemas.enable=true
ENV value.converter.schemas.enable=true

ENV internal.key.converter=org.apache.kafka.connect.json.JsonConverter
ENV internal.value.converter=org.apache.kafka.connect.json.JsonConverter
ENV internal.key.converter.schemas.enable=false
ENV internal.value.converter.schemas.enable=false

ENV offset.storage.topic=$(echo $kafka_prefix)connect-offsets
ENV offset.storage.replication.factor=1

ENV config.storage.topic=$(echo $kafka_prefix)connect-configs
ENV config.storage.replication.factor=1
ENV status.storage.topic=$(echo $kafka_prefix)connect-status
ENV status.storage.replication.factor=1
ENV offset.flush.interval.ms=10000

RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1 \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.0.1




#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors ; 'bash'

