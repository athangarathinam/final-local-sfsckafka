#!/bin/bash
#cd /usr/share/java/plugins
#java -jar snowflake-kafka-connector-1.5.1.jar

#cd /usr/share/java/kafka-connect-jdbc
#java -jar snowflake-jdbc-connector-3.12.17.jar

#cd /etc/kafka-connect/jars
#java -jar bc-fips-1.0.2.jar

#cd /etc/kafka-connect/jars
#java -jar bcpkix-fips-1.0.5.jar

#!/usr/bin/env bash

echo $HEROKU_APP_NAME

#SERVER_HOST=$HEROKU_APP_NAME.herokuapp.com
SERVER_HOST=$HEROKU_APP_NAME
SERVER_URL=https://$SERVER_HOST


export CONNECT_REST_PORT=$PORT
export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

kafka_addon_name=${KAFKA_ADDON:-KAFKA}
prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
kafka_prefix=$(echo ${!prefix_env_var})
kafka_url_env_var="$(echo $kafka_addon_name)_URL"
postgres_addon_name=${POSTGRES_ADDON:-DATABASE}

CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//} \
CONNECT_GROUP_ID=$(echo $kafka_prefix)connect-cluster \

CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets \

CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs \

CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status \

CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter" \
CONNECT_REST_ADVERTISED_HOST_NAME="localhost" \
CONNECT_PLUGIN_PATH=/usr/share/java \

curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties $SERVER_URL/connectors
sleep infinity
