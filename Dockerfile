
# this is an official Python runtime, used as the parent image
FROM python:3.8-buster

# add the current directory to the container as /app
COPY ./app /app

# set the working directory in the container to /app
WORKDIR /app

# Install OpenJDK-11
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get purge -y \
    && apt-get clean -y \
    && apt-get autoremove -y \
    && rm -rf /tmp/* /var/tmp/* \
    && rm -rf /var/lib/apt/lists/*

# and internal root ca certs
COPY .build/certs/*.crt /usr/local/share/ca-certificates/

RUN update-ca-certificates && pip install --trusted-host pypi.python.org wheel \
    && pip install --trusted-host pypi.python.org -r requirements.txt

# execute the Flask app
CMD python kafka-salesforce-prod.py
