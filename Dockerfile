
# this is an official Python runtime, used as the parent image
FROM confluentinc/cp-kafka-connect-base

# Install Snowflake Kafka Connector
RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1

# # and internal root ca certs
# COPY .build/certs/*.crt /usr/local/share/ca-certificates/
COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties

# RUN update-ca-certificates
CMD curl -VVV -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com/connectors
