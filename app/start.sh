#!/bin/bash

cd /usr/share/java/plugins
java -jar snowflake-kafka-connector-1.5.1.jar

cd /usr/share/java/kafka-connect-jdbc
java -jar snowflake-jdbc-connector-3.12.17.jar

cd /etc/kafka-connect/jars
java -jar bc-fips-1.0.2.jar

cd /etc/kafka-connect/jars
java -jar bcpkix-fips-1.0.5.jar
