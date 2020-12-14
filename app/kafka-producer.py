import snowflake.connector
import os
import json
# import ssl
import kafka_helper
from kafka import KafkaProducer  # ,  KafkaConsumer

V_KAFKA_URL = os.environ.get('KAFKA_URL')
V_KAFKA_TRUSTED_CERT = os.environ.get('KAFKA_TRUSTED_CERT')
print("Kafka URL" , V_KAFKA_URL)
print("Kafka T_CERT", V_KAFKA_TRUSTED_CERT)
V_SSL_CONTEXT = kafka_helper.get_kafka_ssl_context()
print("SSL Context",V_SSL_CONTEXT)

conn= snowflake.connector.connect(
    account = 'wda05749',
    user = 'ATHANGARATHINAM',
    password = 'Pradev2023',
    database = 'SALES_FORCE_POC',
    schema = 'PUBLIC',
    warehouse = 'WH_SF_KAFKA_POC')
cur = conn.cursor()
tablval = cur.execute("select * from test1").fetchall()
print(tablval)
