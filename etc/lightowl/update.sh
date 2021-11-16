#!/bin/bash

cd /home/lightowl

/usr/bin/echo "Stopping LightOwl"
/usr/local/bin/docker-compose down

/usr/bin/echo "Download new Docker Images"
/usr/local/bin/docker-compose pull

/usr/bin/echo "Launching LightOwl"
/usr/local/bin/docker-compose -f ./docker-compose.yml up -d