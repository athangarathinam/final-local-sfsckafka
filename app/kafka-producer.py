import snowflake.connector
import os
import json
import ssl
import kafka_helper
from kafka import KafkaProducer   ,  KafkaConsumer

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
  
def get_kafka_consumer(topic=None,
                       value_deserializer=lambda v: json.loads(v.decode('utf-8'))):
    """
    Return a KafkaConsumer that uses the SSLContext created with create_ssl_context.
    """

    # Create the KafkaConsumer connected to the specified brokers. Use the
    # SSLContext that is created with create_ssl_context.
    print("Topic Used - ---",  topic)
    consumer = KafkaConsumer(
        topic,
        #bootstrap_servers=get_kafka_brokers(),
        bootstrap_servers=V_KAFKA_URL.split(",")[0].replace("kafka+ssl://",""),
        security_protocol='SSL',
        ssl_context=V_SSL_CONTEXT,
        value_deserializer=value_deserializer
    )

    return consumer 

if __name__ == '__main__':
  print("Hi Main")
    # Create the Producer
    PRODUCER = fn_kafka_producer()

    # Create a producer Record
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!12')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!123')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!1234')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!12345')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!12')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!123')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!1234')
    PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!12345')
    PRODUCER.flush()
    
    print("Consumer Test First @@@@@@@@@@@@@@ -- 123456789")
    #Create the Consumer
    CONSUMER = get_kafka_consumer(topic='salfrs_kafka_snowflake')
    print("Consumer Test @@@@@@@@@@@@@@ -- 123456789")
    #CONSUMER.flush()
    
    for message in CONSUMER:
      print("Consumer Test Inside FOr loop @@@@@@@@@@@@@@ -- 123456789")
      print ("%s:%d:%d: key=%s value=%s" % (message.topic, message.partition,
                                              message.offset, message.key,
                                                  message.value))
      print("Consumer Test After For loop @@@@@@@@@@@@@@ -- 123456789")
      print(message.value['Body'])  
      print("Consumer Test After Body Print @@@@@@@@@@@@@@ -- 123456789")
    
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
