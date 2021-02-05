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

#echo "======== Before PORT =====" 

#export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

#echo "======== After PORT ====="

[ -z $addon ] && {
  echo "addon is missing" >&2
  exit 1
}

client_key="$KAFKA_CLIENT_CERT_KEY"
client_cert="$KAFKA_CLIENT_CERT"
trusted_cert="$KAFKA_TRUSTED_CERT"

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

echo -n "${client_key}" >> /etc/kafka/keystore.pem
echo -n "${client_cert}" >> /etc/kafka/keystore.pem
echo -n "${trusted_cert}" > /etc/kafka/truststore.pem

keytool -importcert -file /etc/kafka/truststore.pem -keystore /etc/kafka/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in /etc/kafka/keystore.pem -out /etc/kafka/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD
keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore /etc/kafka/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore /etc/kafka/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD

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
export CONNECT_PRODUCER_SSL_TRUSTSTORE_LOCATION=/etc/kafka/truststore.jks
export CONNECT_PRODUCER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEYSTORE_LOCATION=/etc/kafka/keystore.jks
export CONNECT_PRODUCER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

export CONNECT_CONSUMER_SECURITY_PROTOCOL=SSL
export CONNECT_CONSUMER_SSL_TRUSTSTORE_LOCATION=/etc/kafka/truststore.jks
export CONNECT_CONSUMER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEYSTORE_LOCATION=/etc/kafka/keystore.jks
export CONNECT_CONSUMER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

export CONNECT_SECURITY_PROTOCOL=SSL
export CONNECT_SSL_TRUSTSTORE_LOCATION=/etc/kafka/truststore.jks
export CONNECT_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_SSL_KEYSTORE_LOCATION=/etc/kafka/keystore.jks
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

export CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"

export CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-offsets
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=3
#OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets

export CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-configs
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=3
#CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs

export CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-status
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=3
#STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status

export CONNECT_OFFSET_FLUSH_INTERVAL_MS=10000

echo "======== After CONNECT_STATUS_STORAGE_TOPIC ====="

echo "======== Before PORT =====" 

#export PORT=$PORT:9092

#export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_PORT=9092
export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 

echo "======== After PORT ====="
echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS "

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
/etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

echo "Heroku Port - $CONNECT_REST_PORT"

#wget https://repo1.maven.org/maven2/com/snowflake/snowflake-kafka-connector/1.5.1/snowflake-kafka-connector-1.5.1.jar
#cp snowflake-kafka-connector-1.5.1.jar /etc/kafka

#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties $SERVER_URL/connectors
curl -X POST https://SERVER_HOST/connectors -H "Content-Type: application/json" --data @-
{
  "name":"KafkaSinkConnectortoSnowflakes",
  "config":{
    "connector.class":"com.snowflake.kafka.connector.SnowflakeSinkConnector",
    "tasks.max":"8",
    "topics":"neat-connector-4307,neat-connector-4307.salesforce.period",
    "snowflake.topic2table.map": "neat-connector-4307:PERIOD,neat-connector-4307.salesforce:PERIOD",
    "buffer.count.records":"10000",
    "buffer.flush.time":"60",
    "buffer.size.bytes":"5000000",
    "snowflake.url.name":"wda05749.snowflakecomputing.com:443",
    "snowflake.user.name":"MMUSAPETA",
    "snowflake.private.key":"MIIFLTBXBgkqhkiG9w0BBQ0wSjApBgkqhkiG9w0BBQwwHAQIIJRKoaZhtIICAggAMAwGCCqGSIb3DQIJBQAwHQYJYIZIAWUDBAEqBBDA1TySLeWMwLitXy2gsVkNBIIE0KHPYkRMRy96cn3zi6skIjQtaM1cmxYvSa6AqdkNZRWpFgMrcapcIKakQXZi+nX1WQGhLIqc86/DaRJjh8MtWxJGK68roTzOfpI214ewO7h8lG+Vx1ge1Cyednt6yKkcCtgoti7lUCiNpm9SpaXe1bQpWDSyk9htyi1pwXBKojLZqEFC39GNMON3Gv7+hoBccbEdngdc37ovr+Sdn6ST5pDXX5B5qQh2nJj+YwH2RZmQIQxJCg4jHXQqx2nUCtB6mydQ6YD52TkZoBwROyVo51rL1wfSueg6Xt0v+Z6e7IpeID3pOiFHRIDcGp7GVXW+KGwPgUe02X2ELQy0ACiY4bkRsC/2yORGjzYsI1C7w/RfDP0QfndxEJ2uU5BzPBGSx2qpaXwLM+nsQVxRoGvhDKjEjb425ldf6ZhHq2U0xgccZHQn0KKmsxmM0RqskxDdF47QnFgC8B8XJUMKcbcWO0sO2rl+m2pfm6iJlw6t6D5pmjxn53VX2zid4VsyOgITXuNg2Ui8WCDZw/sqhTVKMQ1GEx2J8oOE0+5h7VwjiTFvEgyZq0facXLFLOsj6xRH4VechHDQbw3QUkac17bGSXzpHzJD7IadnfVOMqdLfCEq668OVKnuV4iKeeZvqTxzNBNzMQUWYi01e/9gfEylgsIsQPt+Tl2ahDpucoUVAbGiMGzY5OCNUtpuZDTPIZTQaoI650Dn2yRIPvbxtC+ET3/MbwqHyzn1LJQ8zFsUovIR8/lY9WJ99ok/IgbH/XcFhrgXAhtzuKk0pTioviKCn0BjmB+kyc/YNmRMdo/JeYY0o+7wtuYtsnqng2VyMytLFk5qF0L3wuusyTY+UoHDwuhH9QsH0f26p5wVc4/YckltU714t6lAwske+F35x1/PA8D8W5JlLkLZVFOlg4Q8V0wAyeTc0HnLEDCJDRSzu/LqNz/UPwJOSf0zUUEUYtGMC4MHHVAni5E22ciyXUzXS0dy3ZCqLafdxYLk6TusuRoT2/BF34wszFE2ix0c61noYi9FjCAkYTTk4nRSxs5IIUb8ULfrdL7vFFjrfA/B8sFcUG95ZLcpNbWy+xElnQDiroxTnI8PxQXB6sY/XrGbwkVKMeapzvhQ6cc4ZPhAidUxT2UJYzE/N5CWgGtqvhBicZA97B45FaeMqbjWGHjtRAeotSc7DQh4Cwu7xXMZOJ6kxtgUd9QN64C39DMaoKOfOrgoXVz904A6r1mjVrTWR8XSUG5pE/34LgOkG30gf+VjXiRt/wZl/N4XmgnLjHTQrvaKVzLiHMKLXRzml/1tJy5bk0WbNVVBdk4YTdnjOd5/VDVEWmdM2DSzi4kolZgyv7B7htJeYgXHEyO7TmJRr97vsVK8OCcFSDLhERMfly1tet5zxpwD6PW7qoO3pnQtmcj/6rAbXwW75WwXQ0q4c8QaAYO2GJg7PJ95AuXRti0QrGXWSj5R118Eex+GSepcD37uQz+XG7d7x1MU4LBPvr4CtB3MsR4R1If+c9zmnxw+rlr4fCW1za7bkoLdl48i0u1mJbf4RdsmBdDDzzFfdXJmk5I7Cb2N+NUs7c6SQLW4nvr6MnKxDwa1UFJBzLta/vmkz/CW7uj0XsOBEQe7kaLigOXDt5VQ9SHmByHuXhHO",
    "snowflake.private.key.passphrase":"SKgN3+WK?"y+SaG%",
    "snowflake.database.name":"SF_KAFKA_SF",
    "snowflake.schema.name":"SF_KAFKA",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter:"com.snowflake.kafka.connector.records.SnowflakeJsonConverter"
      }
   }
sleep infinity
