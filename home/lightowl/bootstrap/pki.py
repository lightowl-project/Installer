from x509 import gen_ca, gen_cert
import subprocess
import secrets
import sys
import os


if __name__ == "__main__":
    ip_address = sys.argv[1]
    pki_config: dict = {
        "country": "FR",
        "state": "59",
        "city": "Lille",
        "organization": "lightowl.io",
        "organizational_unit": "Internal PKI",
        "commonName": "LIGHTOWL_PKI_" + secrets.token_urlsafe(16)
    }

    """ Nothing to do if PKI is already set up """
    if os.path.isfile("/etc/ssl/lightowl/ca.key"):
        print("Warning: CA certificate already exists... ignoring CA creation")
    else:

        """ Build CA Certificate """
        print("Creating CA certificate and private key")
        
        ca_cert, ca_key = gen_ca(pki_config)

    """ Build node certificate (overwrite if it exist) """
    hostname = subprocess.check_output(['hostname']).strip().decode('utf-8')
    cert, key = gen_cert(
        hostname,
        ca_cert,
        ca_key,
        ip_address=ip_address,
        commonName=pki_config["commonName"]
    )

    """ Generate Diffie Hellman configuration """
    os.system("openssl dhparam -out /etc/ssl/lightowl/dh2048.pem 2048")
