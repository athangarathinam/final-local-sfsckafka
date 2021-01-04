
# this is an official Python runtime, used as the parent image
FROM confluentinc/cp-kafka-connect-base

# Install Snowflake Kafka Connector
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get purge -y \
    && apt-get clean -y \
    && apt-get autoremove -y \
    && confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1 \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /var/lib/apt/lists/*

# # and internal root ca certs
# COPY .build/certs/*.crt /usr/local/share/ca-certificates/

# RUN update-ca-certificates
