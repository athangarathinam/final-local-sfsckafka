#!/usr/bin/env bash

echo $APP_NAME

echo "======== $APP_NAME ====="

SERVER_HOST=$APP_NAME.herokuapp.com
SERVER_URL=https://$SERVER_HOST


echo "======== Before PORT =====" 

export CONNECT_REST_PORT=$PORT
export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

echo "======== After PORT ====="

kafka_addon_name=${KAFKA_ADDON:-KAFKA}
prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
kafka_prefix=$(echo ${!prefix_env_var})
kafka_url_env_var="$(echo $kafka_addon_name)_URL"
postgres_addon_name=${POSTGRES_ADDON:-DATABASE}

echo "Variables: $kafka_addon_name $prefix_env_var $kafka_prefix $kafka_url_env_var $postgres_addon_name "

echo "======== After postgres_addon_name ====="

export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}

export CONNECT_GROUP_ID=$(echo $kafka_prefix)connect-cluster
#GROUP_ID=$(echo $kafka_prefix)connect-cluster

export CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets
#OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets

export CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs
#CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs

export CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status
#STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status

echo "======== After CONNECT_STATUS_STORAGE_TOPIC ====="

#CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#CONNECT_REST_ADVERTISED_HOST_NAME="localhost"
#CONNECT_PLUGIN_PATH=/usr/share/java


#KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
#REST_ADVERTISED_HOST_NAME="localhost"
#PLUGIN_PATH=/usr/share/java

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
/etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties $SERVER_URL/connectors
sleep infinity
