FROM confluentinc/cp-kafka-connect:5.3.1
# Create plugin directory
RUN mkdir -p /usr/share/java/plugins
RUN mkdir -p /usr/share/java/kafka-connect-jdbc
RUN mkdir -p /etc/kafka-connect/jars
# Add Snowflake connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/com/snowflake/snowflake-kafka-connector/1.5.0/snowflake-kafka-connector-1.5.0.jar" -o /usr/share/java/plugins/snowflake-kafka-connector-1.5.0.jar
# Add Snowflake JDBC connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.10.3/snowflake-jdbc-3.10.3.jar" -o /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-connector-3.10.3.jar
# Add bouncycastle jars
COPY bc-fips-1.0.2.jar /etc/kafka-connect/jars/bc-fips-1.0.2.jar
COPY bcpkix-fips-1.0.5.jar /etc/kafka-connect/jars/bcpkix-fips-1.0.5.jar
# RUN apt-get update
RUN apt-get update && apt-get install -y
# datagen config
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

COPY app/start.sh /etc/kafka-connect/start.sh
CMD bash /etc/kafka-connect/start.sh
