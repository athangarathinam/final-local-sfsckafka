#!/usr/bin/env bash

echo $APP_NAME

echo "======== $APP_NAME ====="

SERVER_HOST=$APP_NAME.herokuapp.com
SERVER_URL=https://$SERVER_HOST

#client_key=os.environ.get('KAFKA_CLIENT_CERT_KEY')
#client_cert=os.environ.get('KAFKA_CLIENT_CERT')
#trusted_cert=os.environ.get('KAFKA_TRUSTED_CERT')

#source /certs/setup-certs.sh
#/etc/kafka/setup-certs.sh
#./etc/kafka/kafka-generate-ssl-automatic.sh

echo "Client Cert Key: CK-$client_key"
echo "Client Cert: TP-$client_cert" 
echo "Trusted Cert: KP-$trusted_cert"

echo "======== Before PORT =====" 

export CONNECT_REST_PORT=$PORT
export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

echo "======== After PORT ====="

#set -e

#addon="$1"

#[ -z $addon ] && {
  #echo "addon is missing" >&2
  #exit 1
#}

#client_key="$(echo $addon)_CLIENT_CERT_KEY"
#client_cert="$(echo $addon)_CLIENT_CERT"
#trusted_cert="$(echo $addon)_TRUSTED_CERT"

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

#echo -n "${!client_key}" >> /etc/kafka/client_key.pem
#echo -n "${!client_cert}" >>  /etc/kafka/client_cert.pem
#echo -n "${!trusted_cert}" >  /etc/kafka/truststore.pem

echo -n "$client_key" >>   /etc/kafka/client_key.pem
echo -n "$client_cert" >>  /etc/kafka/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka/truststore.pem

if [ "$?" = "0" ]; then
  echo "++++++++++ No Error while creating .pem files +++++++++"
else
  echo "++++++++++ Error while creating .pem files +++++++++"
  exit 1
fi

echo -ne "test" > /etc/kafka/test.txt
touch /etc/kafka/test1.txt

echo "keystore - $ /etc/kafka/keystore.pem"
echo "trusted - $ /etc/kafka/truststore.pem"

keytool -importcert -file  /etc/kafka/truststore.pem -keystore  /etc/kafka/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka/client_cert.pem -inkey  /etc/kafka/client_key.pem -out  /etc/kafka/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD
keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD

#rm -f .{keystore,truststore}.{pem,pkcs12}

kafka_addon_name=${KAFKA_ADDON:-KAFKA}
prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
kafka_prefix=$(echo ${!prefix_env_var})
kafka_url_env_var="$(echo $kafka_addon_name)_URL"
postgres_addon_name=${POSTGRES_ADDON:-DATABASE}

export CONNECT_SECURITY_PROTOCOL=SSL
export CONNECT_SSL_TRUSTSTORE_LOCATION=/ect/kafka/truststore.jks
export CONNECT_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_SSL_KEYSTORE_LOCATION=/ect/kafka/keystore.jks
export CONNECT_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

echo "Variables: $kafka_addon_name $prefix_env_var $kafka_prefix $kafka_url_env_var $postgres_addon_name "

echo "Secuirty protocal: H-$HOME TP-$TRUSTSTORE_PASSWORD KP-$KEYSTORE_PASSWORD"

echo "======== After postgres_addon_name ====="

#export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}

export CONNECT_GROUP_ID=$(echo $kafka_addon_name)connect-cluster
#GROUP_ID=$(echo $kafka_prefix)connect-cluster

export CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-offsets
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=3
#OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets

export CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-configs
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=3
#CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs

export CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-status
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=3
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
