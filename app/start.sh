#!/usr/bin/env bash

echo $APP_NAME

echo "======== $APP_NAME ====="
SERVER_HOST="$(echo $APP_NAME).herokuapp.com"
#SERVER_URL=https://$SERVER_HOST
SERVER_URL=http://$SERVER_HOST
export CONNECT_REST_ADVERTISED_HOST_NAME=$(echo $APP_NAME).herokuapp.com
export CONNECT_KAFKA_HEAP_OPTS="-Xms256M -Xmx2G"
KAFKA_HEAP_OPTS="-Xms256M -Xmx1G"

export RANDFILE=/etc/kafka-connect/.rnd
#set RANDFILE=.rnd

#client_key=os.environ.get('KAFKA_CLIENT_CERT_KEY')
#client_cert=os.environ.get('KAFKA_CLIENT_CERT')
#trusted_cert=os.environ.get('KAFKA_TRUSTED_CERT')

#source /certs/setup-certs.sh
#/etc/kafka/setup-certs.sh
#./etc/kafka/kafka-generate-ssl-automatic.sh

#echo "======== Before PORT ====="

#export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST"

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST"

#echo "======== After PORT ====="

 #[ -z $addon ] && {
 # echo "addon is missing" >&2
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

#echo -n "${!client_key}" >> /etc/kafka-connect/client_key.pem
#echo -n "${!client_cert}" >>  /etc/kafka-connect/client_cert.pem
#echo -n "${!trusted_cert}" >  /etc/kafka-connect/truststore.pem

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

#rm -f .{keystore,truststore}.{pem,pkcs12}

#kafka_addon_name=${KAFKA_ADDON:-KAFKA}
#prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
#kafka_prefix=$(echo ${!prefix_env_var})
#kafka_url_env_var="$(echo $kafka_addon_name)_URL"
#postgres_addon_name=${POSTGRES_ADDON:-DATABASE}

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

#export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}

export CONNECT_GROUP_ID=kafka-snowflake-connect-cluster
#export CONNECT_GROUP_ID="kafka-dimensional-99909_PREFIX"
#GROUP_ID=$(echo $kafka_prefix)connect-cluster

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

#export PORT=$PORT:9092

export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_PORT=9092
#export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST"

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST"

echo "======== After PORT ====="
echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS"

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
 /etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

echo "Heroku Port - $CONNECT_REST_PORT"

#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties $SERVER_URL/connectors
#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com
#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com/connectors

curl -vvv -X POST http://sfsc-kafka-c1-test.herokuapp.com/connectors/ -H "Content-Type: application/json" --data '{
    "name":"KafkaSinkConnectortoSnowflakes",
	"config":{
		"connector.class":"com.snowflake.kafka.connector.SnowflakeSinkConnector",
		"tasks.max":"8",
		"topics":"sf_kafka_sf.salesforce.navigationmenuitem",
		"snowflake.topic2table.map":"sf_kafka_sf.salesforce.navigationmenuitem:PERIOD",
		"buffer.count.records":"10000",
		"buffer.flush.time":"60",
		"buffer.size.bytes":"5000000",
		"snowflake.url.name":"wda05749.snowflakecomputing.com:443",
		"snowflake.user.name":"MMUSAPETA",
		"snowflake.private.key":"MIIEogIBAAKCAQEAvlj42xPbTSt0BpK03W52qwwJykpq1ImWnDkBNwS0jj6hBKdQ5GsrN9FWemcsKjxJIM32XGAcC5VGyTYzzQEkLVOfzdDaye8vkbyaPcHzcDxfc1t94Fe/SnGYj76w/6Stel/PuqGXlEALYZEF7u3pQeA/pz0KcK0vt+aYOBKr1sBcy+uPZ22t37WduZNral59kwkx8U0Y9Sj7MPq7mzu5lnHNqXfJ/yG6n4lPxCKP98+XelKHANLCrGKrC72cq0WZu9iMuvEX4jB71eiS7RryCGBv565nPiblXddnDHKcIzzvzhidP9FcHQA1UFYW0o4fw8Rfg4SCOY/9xDb/y21dGwIDAQABAoIBAE5hvuAf1h959EY8pUPFmBIpW+K0MDejDKT6CFkKk/s7KP0MlQ/qXZqXll/DGnmt54MdrQQvA311k/eJXV1eyfHsTJLpHR8oYlNF8dHaiw89nSSYmUYHfBsAmg0fPi2XN2R8DcNRhWSj1svvdx0DVRkuaafJSAJMHqlAyI/WiHJegCS2qvLWZqk1yOK+c0zc4IQzAaONCMP3dVN/a6+fN/mU8tccCb0CN3+pr8/Wp3qIiB3gaJYxtK52n71Te7ogBKKg98ZMtM4WIbonWz9D2fRVBJZCVoojOtNkfAuPK6sUPLArwc04iz1jZtpewoSdARtxivtHSuSRISo/JyLha3ECgYEA5ddUsdEu8TOiYnqeyx4YnKxvynkFOLCIU6ZINtlZBxqgQoFc873aWtkLPOdN1hgcLb6pyTbL0/Gxu8Ylb0t77bPi0TCkJt22OhXW6PNEhH3Ij4xJHzgIbBCZLDGZgs0FGtSWYrsNe2fNpWitUi26cxfFEGVqb5feouFFwnFviiMCgYEA1ALz9wE02QoFThSH4K+vYPYy5kO7LQxTY0fVJBM9Iavp3J9Ow9eV7snF3A6GIZLTZz5rWk2iPUM9a84gAemt7XWwVC1+dSj9boMhPHtoF/TdoMnSzLhAEHS9c+AGfz44Iz/o8Zvq1SUbmoWf5lWy4kX1jakqK0I8Bk4o/rls5KkCgYB5vld0YNM2nB0VgNH/0Q9EXepRG01yu79aX6e8td/8bVQaJh+wVA4HNRRIzFRkZRz39hhFJqtMtqdoSQqnKxqXzEMGf3dTxvixR8QwXDsc2uuTbcGFsc50P06DJDqmGCbuEVEfNulrRo6dYRb9go9SS3LsvmtkdNNO/3hOCHwGdQKBgG84DVuqmlqxUw8e3hkUkOBAx3rcVTjQmn4elMWUAiHD2a8PM3axhcn6t301cU/zgktLB24cA9w3heUkAM6AE+naL2I5a3lyw2BSEgF0i6rlnc5XkeorThBT7X74KvBdZ322bTEyJgMisFRjfPqMQodJRAPIloKTAIIeRos6ItHhAoGAS1nRHTjZEOO8rMiQXw2HVSP9+IMSB1Fvq08YKThB1yuF/FQx4NJytdJUQtUBmSrm/2XIQFY5GRzumli7QOPZSEucmXGHZCpa0Q3s0THJop50f6OcTOkZmJjS0LzNERn9ZtI1w76QF+5rW4TyVArnIOnsrY7gga7jlj8n/ot+F7E=",
		"snowflake.database.name":"SF_KAFKA_SF",
		"snowflake.schema.name":"SF_KAFKA",
		"key.converter":"org.apache.kafka.connect.storage.StringConverter",
		"value.converter":"com.snowflake.kafka.connector.records.SnowflakeJsonConverter"
		   }
		}'  
sleep infinity
 #KAFKA_HEAP_OPTS="-Xms256M -Xmx256M " /usr/bin/connect-distributed /etc/kafka-connect/connect-distributed.properties
#exec /etc/confluent/docker/run
