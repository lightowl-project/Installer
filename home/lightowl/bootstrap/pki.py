from x509 import mk_ca_cert_files, mk_signed_cert_files
import subprocess
import secrets
import os


if __name__ == "__main__":
    pki = {
        "country": "FR",
        "state": "59",
        "city": "Lille",
        "organization": "lightowl.io",
        "organizational_unit": "Internal PKI"
    }

    """ Nothing to do if PKI is already set up """
    if os.path.isfile("/etc/ssl/lightowl/ca.key"):
        print("Warning: CA certificate already exists... ignoring CA creation")
    else:

        """ Build CA Certificate """
        print("Creating CA certificate and private key")
        ca_name = "LIGHTOWL_PKI_" + secrets.token_urlsafe(16)
        cacert, cakey = mk_ca_cert_files(
            ca_name,
            pki["country"],
            pki["state"],
            pki["city"],
            pki["organization"],
            pki["organizational_unit"]
        )

    """ Build node certificate (overwrite if it exist) """
    hostname = subprocess.check_output(['hostname']).strip().decode('utf-8')
    cert, key = mk_signed_cert_files(
        hostname,
        pki["country"],
        pki["state"],
        pki["city"],
        pki["organization"],
        pki["organizational_unit"],
        2
    )

    """ Generate Diffie hellman configuration """
    os.system("openssl dhparam -out /etc/ssl/lightowl/dh2048.pem 2048")
