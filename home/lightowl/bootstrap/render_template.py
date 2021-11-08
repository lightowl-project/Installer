import os
import sys
import jinja2
import base64
import hashlib


def rabbitmq(password: str):
    with open("/home/lightowl/bootstrap/templates/definitions.json.j2", 'r') as f:
        template: str = f.read()

    j2_template = jinja2.Template(template, autoescape=True)
    salt = os.urandom(4)

    tmp = salt + password.encode("utf-8")
    password_hash: str = hashlib.sha256(tmp).digest()

    salted_hash = salt + password_hash
    base64_password: str = base64.b64encode(salted_hash)

    with open("/home/rabbitmq/definitions.json", 'w') as f:
        f.write(j2_template.render({
            "password": base64_password.decode("utf-8")
        }))


def telegraf_input(password: str):
    with open("/home/lightowl/bootstrap/templates/lightowl.conf.j2", 'r') as f:
        template: str = f.read()

    j2_template = jinja2.Template(template, autoescape=True)
    with open("/home/telegraf/telegraf.d/lightowl.conf", "w") as f:
        f.write(j2_template.render({
            "password": password
        }))


def lightowl(password: str):
    with open("/home/lightowl/bootstrap/templates/docker-compose.yml.j2", "r") as f:
        template: str = f.read()

    j2_template = jinja2.Template(template, autoescape=True)
    with open("/home/lightowl/docker-compose.yml", "w") as f:
        f.write(j2_template.render({
            "rabbit_password": password
        }))

def telegraf_output():
    with open("/home/lightowl/bootstrap/templates/telegraf.conf.j2", "r") as f:
        template: str = f.read()

    j2_template = jinja2.Template(template, autoescape=True)
    with open("/home/telegraf/telegraf.conf", "w") as f:
        f.write(j2_template.render())


if __name__ == "__main__":
    password: str = sys.argv[1]
 
    rabbitmq(password)
    telegraf_input(password)
    lightowl(password)
    telegraf_output()
