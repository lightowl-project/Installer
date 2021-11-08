#!/bin/bash

cd /home/lightowl

/usr/bin/echo "Stopping LightOwl"
/usr/local/bin/docker-compose down

/usr/bin/echo "Removing LightOwl Docker images"
/usr/bin/docker rmi raznak/lightowl-server:0.1
/usr/bin/docker rmi raznak/lightowl-worker:0.1
/usr/bin/docker rmi raznak/lightowl-collector:0.1

/usr/bin/echo "Launching LightOwl"
/usr/local/bin/docker-compose -f ./docker-compose.yml up -d