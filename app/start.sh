#!/usr/bin/env bash

echo $APP_NAME

echo "======== $APP_NAME ====="

SERVER_HOST=$APP_NAME.herokuapp.com
SERVER_URL=https://$SERVER_HOST

#client_key=os.environ.get('KAFKA_CLIENT_CERT_KEY')
#client_cert=os.environ.get('KAFKA_CLIENT_CERT')
#trusted_cert=os.environ.get('KAFKA_TRUSTED_CERT')

./certs/setup_certs

echo "Client Cert Key: CK-$client_key"
echo "Client Cert: TP-$client_cert" 
echo "Trusted Cert: KP-$trusted_cert"

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

echo "Secuirty protocal: H-$HOME TP-$TRUSTSTORE_PASSWORD KP-$KEYSTORE_PASSWORD"

echo "======== After postgres_addon_name ====="

#export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}

export CONNECT_GROUP_ID=$(echo $kafka_addon_name)connect-cluster
#GROUP_ID=$(echo $kafka_prefix)connect-cluster

export CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-offsets
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=1
#OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets

export CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-configs
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=1
#CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs

export CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-status
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=1
#STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status

echo "======== After CONNECT_STATUS_STORAGE_TOPIC ====="

export CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"

echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS "

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
/etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties $SERVER_URL/connectors
sleep infinity
