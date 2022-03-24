#!/bin/bash

python3 /home/lightowl/bootstrap/pki.py $2
python3 /home/lightowl/bootstrap/render_template.py $1 $3
