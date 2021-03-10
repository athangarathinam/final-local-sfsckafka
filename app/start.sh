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

export CONNECT_GROUP_ID=kafka-connect-snowflake-cluster

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

curl -vvv -X POST -H "Content-Type: application/json" --data '{
    "name":"KafkaSinkConnectortoSnowflakes",
	"config":{
		"connector.class":"com.snowflake.kafka.connector.SnowflakeSinkConnector",
		"tasks.max":"8",
		"topics":"salesforce_kafka_snowflakes.salesforce.calendar",
		"snowflake.topic2table.map": "salesforce_kafka_snowflakes.salesforce.calendar:CALENDAR",
		"buffer.count.records":"10000",
		"buffer.flush.time":"60",
		"buffer.size.bytes":"5000000",
		"snowflake.url.name":"https://wda05749.snowflakecomputing.com:443",
		"snowflake.user.name":"MMUSAPETA",
		"snowflake.private.key":"MIIFLTBXBgkqhkiG9w0BBQ0wSjApBgkqhkiG9w0BBQwwHAQI94ng57q0DYcCAggAMAwGCCqGSIb3DQIJBQAwHQYJYIZIAWUDBAEqBBA2vp7JZgq58XsXCEMWvoO3BIIE0I9xLbeC4ncRvSFpHE9yETXo2cGlYBFpNMeJIu4cLnb3ymuCAUZ9pxrolc/74sDy/s8YABbEfKtxk/Da3qhv5rJH7nN6dtdZ42Jh2fX8WgYNibjyXLIn1qCIupe7lBZy/XSf3cEuvzkjY4HZb+pbAc+hm1oizJ0bSerboVaNkdJ6/XK0i3OWABkbvzATMkPUhI5dTWGFUMMUtIhjJEeO0zQRz2vfYdVwTuwNjfuqauPSrYqXBGr63BOKWS/EvTprdr/Cc0yBnJjWZ+GuF2zLtXy4tNkPSADRZA+u6INcvWmGYfKbaxhvMEyOxMVjpnLUsW+uR1/i8PAFTt2KXb9SM0ieE9qmgo1c+gtjr4SK0UYvRBbm3tE814BzK4HMwZZJ4j3sfjb+abr+OOM1QcWiSyfG588+/e5f5jCAegZMsHIt082ZC4LMHun+2dD7OYCnz9HzHbIIapPq2i+LR/Sr7Rb+iaC3a8kM84F8FvO/mqmv/BvXkviuL4cGv48dHO1Jhl8pN5BNJREtAi7WvyKCIPRtK27r2SBigcFC7K6alKa5QqAcIflMK6WQjp2/BewOIoCUTq7OPqgzpjFhknSF3kyg0mXG22XSjbwRLc67DchUQa3Lvnc00QDR9kQBqp2e+NqsIFxUvIFK+zJ6EoROfqLmyWQpKH9TAcoZweZrE7wzl9JFGUbAwsqMFJDVsbsoQz8SlVGJTZvirlKBpkiNTEUhuoEtYh8uOwJFeASc4WqBMJYG1tYg3o1kMgAfgkoBuyI6oEpemwucBZNac9u6gGJ2TTDItDsf3Ts+a8oIfTauarWU5oqiFU3wo1EebrfywjgnB4csu2Dzy2Yzwag6kvRLJXoWzBSy+P54CPaUdbXk9pwaetjpcf37MthbcH0w32Q3eTMwFP9Ha675X+lUwGWW2JQALJSKiUzRxfgHux9eMSr631Juk54JdmTOGFiX7twykjXEnm9mcWm5W1SHIjwxbdWf36sprZQwjJZYZZwswRbkH9M/qv1RMBm+aRt7JvPs3UBME7SjS/3KoXX1zYSCmJC78rhvSn1NwqR8zPejioqlvpNSj1x9I93gI8RotGnqgWwNhMEmYOMIQsKtT/oslhg/bqmspZ6L2p4ysjJ10Xsuni1uWIQQ7Fmfy6cEVvdvTyYVDbrDYfCUx4hA421eKPk7El5MDb3RY6yUqT+ND5O3FZIFPxRoCtiF4QGtrHZeqbVVRB0Bio6V88R5xK6Yu6yCedXvd37u/SQLLxnEhjXyb5amcKawxsnhaoPkMYHQEZv4eM9FoY2+iv9d7ycCJM+VGg9ArZ8slVvwaMEwif16fZeTAYgCuwJq5s9ePMb1fC3OflRF7r8f5weEqDV8EgoRkW6fIUjoh8ZEN/pZn+csr41uB0LtC+QnYRfvg5no+1JAGGeJxe9V1faFTw5Y7wOt1bOJkkZDVFpxaiw8F994wHxoRBGHp6uog8DxQqDy5AY1LiNmTW8JI5iN+XgbtsHK1Gkv3k/duxVnvVYzg/GmeTiS8CSBftVynY53l57Xn0EVBu5nHvQ51+Sl/aA49CXHU9CWsDpDUxfJnVK5ExTKTZ0XQXKf1MGZLT1iwF0ueK1WCaHJ8KilDQWUzk64s6mAhszyY3+ekaYGVYkl",
		"snowflake.private.key.passphrase":"MNjklpo0897",
		"snowflake.database.name":"SF_KAFKA_SF",
		"snowflake.schema.name":"SF_KAFKA",
		"key.converter":"org.apache.kafka.connect.storage.StringConverter",
		"value.converter":"com.snowflake.kafka.connector.records.SnowflakeJsonConverter"}}' \
		https://sfsc-kafka-c1-test.herokuapp.com/connectors

sleep infinity
