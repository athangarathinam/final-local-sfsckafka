import snowflake.connector
import os
import json
import ssl
import kafka_helper
from kafka import KafkaProducer  # ,  KafkaConsumer

V_KAFKA_URL = os.environ.get('KAFKA_URL')
V_KAFKA_TRUSTED_CERT = os.environ.get('KAFKA_TRUSTED_CERT')
print("Kafka URL" , V_KAFKA_URL)
print("Kafka T_CERT", V_KAFKA_TRUSTED_CERT)
V_SSL_CONTEXT = kafka_helper.get_kafka_ssl_context()
print("SSL Context",V_SSL_CONTEXT)

KAFKA_TOPIC = 'salfrs_kafka_snowflake'



# Create Producer Properties
def fn_kafka_producer(acks='all',
                      value_serializer=lambda v: json.dumps(v).encode('utf-8')):
    kafkaprod = KafkaProducer(
        bootstrap_servers=V_KAFKA_URL.split(",")[0].replace("kafka+ssl://",""),
        # key_serializer=key_serializer,
        value_serializer=value_serializer,
        ssl_context=V_SSL_CONTEXT,
        acks=acks,
        security_protocol="SSL"
    )
    return kafkaprod

if __name__ == '__main__':
    # Create the Producer
    PRODUCER = fn_kafka_producer()

    # Create a producer Record
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!')
    PRODUCER.flush()
    
    # Connect Snowflake
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
