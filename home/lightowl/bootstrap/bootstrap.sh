#!/bin/bash

python3 /home/lightowl/bootstrap/pki.py
python3 /home/lightowl/bootstrap/render_template.py $1 $2
