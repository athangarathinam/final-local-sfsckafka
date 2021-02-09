# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.5.3

RUN CONNECT_REST_PORT=$PORT

RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1 \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.0.1

# Create plugin directory
RUN mkdir -p /usr/share/java/plugins
RUN mkdir -p /usr/share/java/kafka-connect-jdbc
#RUN mkdir -p /etc/kafka/kafka-logs
RUN mkdir -p /etc/kafka-connect/kafka-logs

RUN echo -n >    /etc/kafka-connect/client_key.pem
RUN echo -n >  /etc/kafka-connect/client_cert.pem
RUN echo -n >  /etc/kafka-connect/truststore.pem

#ENV GETUPD=y

#install vim and update 
#RUN dpkg -i debian-archive-keyring_2017.5~deb8u1_all.deb -y \
RUN sed -i 's;http://archive.debian.org/debian/;http://deb.debian.org/debian/;' /etc/apt/sources.list \
   && apt-get update \
   && apt-get install unzip \
   && apt-get install zip \
   && apt-get --yes --force-yes install -y --no-install-recommends apt-utils \
   vim
   
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

#rm -f .{keystore,truststore}.{pem,pkcs12}

echo "Client Cert Key: CK-$client_key"
echo "Client Cert: TP-$client_cert" 
echo "Trusted Cert: KP-$trusted_cert"

#Remove log4j.properties file
#RUN rm /etc/kafka/log4j.properties
#RUN rm /etc/kafka/connect-log4j.properties

#RUN rm /etc/kafka-connect/log4j.properties
#RUN rm /etc/kafka-connect/connect-log4j.properties

# Copy config and certs
#COPY .build/certs/*.crt /usr/local/share/ca-certificates/
#COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties
#COPY app/start.sh /etc/kafka/start.sh
#COPY app/setup-certs.sh /etc/kafka/setup-certs.sh
#COPY app/log4j.properties /etc/kafka/log4j.properties
#COPY app/connect-log4j.properties /etc/kafka/connect-log4j.properties
#COPY app/kafka-generate-ssl-automatic.sh /etc/kafka/kafka-generate-ssl-automatic.sh

COPY .build/certs/*.crt /usr/local/share/ca-certificates/
COPY app/connect-distributed.properties /etc/kafka-connect/connect-distributed.properties
COPY app/start.sh /etc/kafka-connect/start.sh
COPY app/start_test.sh /etc/kafka-connect/start_test.sh
COPY app/setup-certs.sh /etc/kafka-connect/setup-certs.sh
COPY app/log4j.properties /etc/kafka-connect/log4j.properties
COPY app/connect-log4j.properties /etc/kafka-connect/connect-log4j.properties

#Config Log4j at Launching Place
#RUN chmod +x /etc/kafka-connect/log4j.properties
#RUN chmod +x /etc/kafka-connect/connect-log4j.properties

RUN update-ca-certificates

# Confluent Hub Config and Installs
#ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/etc/kafka"
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/etc/kafka-connect"


#RUN chmod +x /etc/kafka/start.sh
#RUN chmod +x /etc/kafka/setup-certs.sh
#RUN chmod +x /etc/kafka/connect-distributed.properties
#RUN chmod +x /etc/kafka/log4j.properties
#RUN chmod +x /etc/kafka/connect-log4j.properties

RUN chmod +x /etc/kafka-connect/start.sh
RUN chmod +x /etc/kafka-connect/start_test.sh
RUN chmod +x /etc/kafka-connect/setup-certs.sh
RUN chmod +x /etc/kafka-connect/connect-distributed.properties


#RUN chmod +x /etc/kafka/kafka-generate-ssl-automatic.sh
#ENTRYPOINT ["source", "/etc/kafka/start.sh"]
#RUN /etc/kafka/setup-certs.sh
#CMD ["/etc/kafka/start.sh"]
CMD ["/etc/kafka-connect/start.sh"]

#CMD ["/etc/kafka-connect/start_test.sh"]

#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors ; 'bash'

