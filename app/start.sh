#!/usr/bin/env bash

echo "======== $APP_NAME ====="

SERVER_HOST="$(echo $APP_NAME).herokuapp.com"
SERVER_URL=http://$SERVER_HOST

export CONNECT_REST_ADVERTISED_HOST_NAME=$(echo $APP_NAME).herokuapp.com
export CONNECT_KAFKA_HEAP_OPTS="-Xms256M -Xmx2G"
KAFKA_HEAP_OPTS="-Xms256M -Xmx1G"

export RANDFILE=/etc/kafka-connect/.rnd

client_key=$KAFKA_CLIENT_CERT_KEY
client_cert=$KAFKA_CLIENT_CERT
trusted_cert=$KAFKA_TRUSTED_CERT

[ -z $TRUSTSTORE_PASSWORD ] && {
  echo "TRUSTSTORE_PASSWORD is missing" >&2
  exit 1
}

[ -z $KEYSTORE_PASSWORD ] && {
  echo "KEYSTORE_PASSWORD is missing" >&2
  exit 1
}

rm -f .{keystore,truststore}.{pem,pkcs12,jks}
rm -f .cacerts

echo -n "$client_key" >   /etc/kafka-connect/client_key.pem
echo -n "$client_cert" >  /etc/kafka-connect/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka-connect/truststore.pem

echo "Cat client_key.pem"
echo ""
cat /etc/kafka-connect/client_key.pem
echo "Cat client_cert.pem"
echo ""
cat /etc/kafka-connect/client_cert.pem
echo "Cat truststore.pem"
echo ""
cat /etc/kafka-connect/truststore.pem
echo ""

if [ "$?" = "0" ]; then
  echo "No Error while creating .pem files"
else
  echo "Error while creating .pem files"
  exit 1
fi

echo "keystore - $ /etc/kafka-connect/client_key.pem"
echo "trusted - $ /etc/kafka-connect/client_cert.pem"
echo "trusted - $ /etc/kafka-connect/truststore.pem"

keytool -importcert -file  /etc/kafka-connect/truststore.pem -keystore  /etc/kafka-connect/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka-connect/client_cert.pem -inkey  /etc/kafka-connect/client_key.pem -out  /etc/kafka-connect/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD
keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka-connect/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka-connect/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD

kafka_addon_name=$KAFKA_ADDON:-KAFKA
prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
kafka_prefix=$(echo $prefix_env_var)
kafka_url_env_var="$(echo $kafka_addon_name)_URL"
postgres_addon_name=$POSTGRES_ADDON:-DATABASE

export CONNECT_PRODUCER_SECURITY_PROTOCOL=SSL
export CONNECT_PRODUCER_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_PRODUCER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_PRODUCER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

export CONNECT_CONSUMER_SECURITY_PROTOCOL=SSL
export CONNECT_CONSUMER_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_CONSUMER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_CONSUMER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

#For log4j 
#export CONNECT_LOG4J_LOGGERS=TRACE, file, stdout, stderr, kafkaAppender, connectAppender, INFO
#export CONNECT_LOG4J_ROOT_LOGLEVEL=TRACE, file, stdout, stderr, kafkaAppender, connectAppender, INFO

export CONNECT_LOG4J_LOGGERS="io.confluent.connect=DEBUG"
#export CONNECT_LOG4J_LOGGERS="io.confluent.connect.jdbc=DEBUG"


export CONNECT_SECURITY_PROTOCOL=SSL
export CONNECT_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

echo "Variables: $kafka_addon_name $prefix_env_var $kafka_prefix $kafka_url_env_var $postgres_addon_name "

echo "Secuirty protocal: H-$HOME TP-$TRUSTSTORE_PASSWORD KP-$KEYSTORE_PASSWORD"

echo "======== After postgres_addon_name ========"


export CONNECT_GROUP_ID=kafka-snowflake-connect-cluster

export CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"

export CONNECT_OFFSET_STORAGE_TOPIC="sf_kafka_sf_offset"
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=3

export CONNECT_CONFIG_STORAGE_TOPIC="sf_kafka_sf_config"
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=3

export CONNECT_STATUS_STORAGE_TOPIC="sf_kafka_sf_status"
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=3

export CONNECT_OFFSET_FLUSH_INTERVAL_MS=10000

echo "======== After CONNECT_STATUS_STORAGE_TOPIC ====="

echo "======== Before PORT ====="

export CONNECT_REST_PORT=$PORT

echo "======== After PORT ====="
echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS"

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
 /etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

echo "Heroku Port - $CONNECT_REST_PORT"

sleep infinity
