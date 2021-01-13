
# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.3.1

# Install Snowflake Kafka Connector
#RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1

# Create plugin directory
RUN mkdir -p /usr/share/java/plugins
RUN mkdir -p /usr/share/java/kafka-connect-jdbc
# Add Snowflake connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/com/snowflake/snowflake-kafka-connector/1.5.1/snowflake-kafka-connector-1.5.1.jar"" -o /usr/share/java/plugins/snowflake-kafka-connector-1.5.1.jar
# Add Snowflake JDBC connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.17/snowflake-jdbc-3.12.17.jar"" -o /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-3.12.17.jar
# Install the below jars 
RUN curl -sSL "https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/1.0.2/bc-fips-1.0.2.jar"" -o /etc/kafka-connect/jars/bc-fips-1.0.2.jar
RUN curl -sSL "https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/1.0.5/bcpkix-fips-1.0.5.jar"" -o /etc/kafka-connect/jars/bcpkix-fips-1.0.5.jar
# copy the properties file
COPY app/connect-distributed.properties /tmp
COPY bc-fips-1.0.2.jar /etc/kafka-connect/jars/
COPY bcpkix-fips-1.0.5.jar /etc/kafka-connect/jars/
# datagen config
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.1.0

# # and internal root ca certs
# COPY .build/certs/*.crt /usr/local/share/ca-certificates/
#COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties

# RUN update-ca-certificates
CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com/connectors
