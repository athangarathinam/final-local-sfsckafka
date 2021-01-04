
# this is an official Python runtime, used as the parent image
FROM confluentinc/cp-kafka-connect-base

# Install Snowflake Kafka Connector
RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1

# # and internal root ca certs
# COPY .build/certs/*.crt /usr/local/share/ca-certificates/

# RUN update-ca-certificates
