# -*- coding: utf-8 -*-
"""
Created on Sat Nov 28 02:15:31 2020

@author: 950027
"""

#import os 
import json
#import ssl
import kafka_helper

from kafka import KafkaProducer#,  KafkaConsumer
from flask import Flask #, abort, request

app = Flask(__name__)

V_KAFKA_URL = 'kafka+ssl://ec2-52-34-50-81.us-west-2.compute.amazonaws.com:9096,kafka+ssl://ec2-44-237-88-58.us-west-2.compute.amazonaws.com:9096,kafka+ssl://ec2-44-240-24-130.us-west-2.compute.amazonaws.com:9096'
V_SSL_CONTEXT = kafka_helper.get_kafka_ssl_context()
KAFKA_TOPIC = 'salfrs_kafka_snowflake'


# Create Producer Properties
def fn_kafka_producer(acks='all',
                       value_serializer=lambda v: json.dumps(v).encode('utf-8')):
    kafkaprod = KafkaProducer(
    bootstrap_servers = V_KAFKA_URL,
    #key_serializer=key_serializer,
    value_serializer =value_serializer,
    ssl_context = V_SSL_CONTEXT,
    acks = acks    
    )
    return kafkaprod

if __name__ == '__main__':
    # Create the Producer
    PRODUCER = fn_kafka_producer()
    
    #Create a producer Record
    PRODUCER.send(KAFKA_TOPIC,'Hello Heroku!!')
    PRODUCER.flush()
    
    
    # Create Producer Properties 
    