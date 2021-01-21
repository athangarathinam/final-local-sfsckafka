
# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.3.1

# Install Snowflake Kafka Connector
#RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1

#ENV GETUPD=y

#install vim and update 
#RUN dpkg -i debian-archive-keyring_2017.5~deb8u1_all.deb -y \
RUN sed -i 's;http://archive.debian.org/debian/;http://deb.debian.org/debian/;' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install unzip \
    && apt-get --yes --force-yes install -y --no-install-recommends apt-utils \
    vim
        

#!/usr/bin/env bash
#RUN curl https://s3.amazonaws.com/heroku-jvm-buildpack-vi/vim-7.3.tar.gz --output vim.tar.gz
#RUN mkdir vim && tar xvf vim.tar.gz -C vim
#RUN export PATH=$PATH:/app/vim/bin

# Create plugin directory
RUN mkdir -p /usr/share/java/plugins
RUN mkdir -p /usr/share/java/kafka-connect-jdbc
RUN mkdir -p /etc/kafka/kafka-logs

# Add Snowflake connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/com/snowflake/snowflake-kafka-connector/1.4.3/snowflake-kafka-connector-1.4.3.jar" -o /usr/share/java/plugins/snowflake-kafka-connector-1.4.3.jar
#CMD ["java","-jar","/usr/share/java/plugins/snowflake-kafka-connector-1.5.1.jar"]

# Add Snowflake JDBC connector jar
RUN curl -sSL "https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.17/snowflake-jdbc-3.12.17.jar" -o /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-connector-3.12.17.jar
#CMD ["java","-jar","/usr/share/java/kafka-connect-jdbc/snowflake-jdbc-connector-3.12.17.jar"]

# Install the below jars 
RUN curl -sSL "https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/1.0.2/bc-fips-1.0.2.jar" -o /etc/kafka-connect/jars/bc-fips-1.0.2.jar
#CMD ["java","-jar","/etc/kafka-connect/jars/bc-fips-1.0.2.jar"]

RUN curl -sSL "https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/1.0.5/bcpkix-fips-1.0.5.jar" -o /etc/kafka-connect/jars/bcpkix-fips-1.0.5.jar
#CMD ["java","-jar","/etc/kafka-connect/jars/bcpkix-fips-1.0.5.jar"]

# copy the properties file
#COPY app/connect-distributed.properties /tmp

#COPY https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/1.0.2/bc-fips-1.0.2.jar /etc/kafka-connect/jars/
#COPY https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/1.0.5/bcpkix-fips-1.0.5.jar /etc/kafka-connect/jars/

#COPY /app/start.sh /etc/kafka/
#RUN chmod +x /etc/kafka/start.sh
#RUN ./etc/kafka/start.sh

# datagen config
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
#RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.1.0
#RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.1

# # and internal root ca certs
# COPY .build/certs/*.crt /usr/local/share/ca-certificates/
COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties

# RUN update-ca-certificates
#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com/connectors
#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors
CMD java -jar "/usr/share/java/plugins/snowflake-kafka-connector-1.4.3.jar" \
   && java -jar "/usr/share/java/kafka-connect-jdbc/snowflake-jdbc-connector-3.12.17.jar" \
   && java -jar "/etc/kafka-connect/jars/bc-fips-1.0.2.jar \
   && java -jar "/etc/kafka-connect/jars/bcpkix-fips-1.0.5.jar \
   && curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors
