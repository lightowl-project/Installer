FROM python:3.10

RUN apt-get update && apt-get upgrade -y && apt-get install -y swig
RUN pip3 install jinja2 m2crypto