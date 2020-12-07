# -*- coding: utf-8 -*-
"""
Created on Sat Nov 28 02:15:31 2020

@author: 950027
"""

import os
import psycopg2
import serialization as serialization

from datetime import datetime



try:
    DATABASE_URL = os.environ['DATABASE_URL']
    connection = psycopg2.connect(DATABASE_URL, sslmode='require')
    cursor = connection.cursor()
    print(connection.get_dsn_parameters(), "\n")
    postgreSQL_select_Query = "select * from period"

    cursor.execute(postgreSQL_select_Query)

    period_records = cursor.fetchall()

    for row in period_records:
        print("Id =", row[3], "\n")
        print("IsForecastPeriod =", row[4])
        print("PeriodLabel =", row[6], "\n")
        print("QuarterLabel =", row[7], "\n")

except (Exception, psycopg2.Error) as error:
    print("Error while connecting to PostgreSQL", error)
# finally:
#     if (connection):
#         cursor.close()
#         connection.close()
#         print("PostgreSQL connection is closed")
#         print(str(datetime.now()) + ":All Feature Successfully completed\n")
