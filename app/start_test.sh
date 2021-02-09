#!/usr/bin/env bash

echo " Hi, Enabling Heroku Error Debug Mode"

echo $APP_NAME

echo "======== $APP_NAME ====="
SERVER_HOST="$(APP_NAME).herokuapp.com
#SERVER_URL=https://$SERVER_HOST
SERVER_URL=http://$SERVER_HOST
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
echo -n "$client_key" >>   /etc/kafka-connect/client_key.pem
echo -n "$client_cert" >>  /etc/kafka-connect/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka-connect/truststore.pem

if [ "$?" = "0" ]; then
  echo "No Error while creating .pem files"
else
  echo "Error while creating .pem files"
  exit 1
fi

echo "keystore - $ /etc/kafka-connect/client_key.pem"
echo "trusted - $ /etc/kafka-connecta/client_cert.pem"
echo "trusted - $ /etc/kafka-connecta/truststore.pem"

keytool -importcert -file  /etc/kafka-connect/truststore.pem -keystore  /etc/kafka-connect/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka-connect/client_cert.pem -inkey  /etc/kafka-connect/client_key.pem -out  /etc/kafka-connect/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD

keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka-connect/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka-connect/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD
    
echo "Client Cert Key: CK-$client_key"
echo "Client Cert: TP-$client_cert" 
echo "Trusted Cert: KP-$trusted_cert"    

curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties http://SERVER_HOST
sleep infinity
