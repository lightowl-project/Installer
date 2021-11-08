FROM rabbitmq:3.6.11-management-alpine

ADD rabbitmq.config /etc/rabbitmq/
ADD definitions.json /etc/rabbitmq/
RUN chown -R rabbitmq:rabbitmq /etc/rabbitmq
RUN chown -R rabbitmq:rabbitmq /etc/rabbitmq/*
