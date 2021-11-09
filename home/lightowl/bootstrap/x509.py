from OpenSSL import crypto
import random
import sys


def gen_ca(config: dict) -> tuple:
    # create a key pair
    k = crypto.PKey()
    k.generate_key(crypto.TYPE_RSA, 4096)

    # create a self-signed cert
    cert = crypto.X509()
    cert.get_subject().C = config["country"]
    cert.get_subject().ST = config["state"]
    cert.get_subject().L = config["city"]
    cert.get_subject().O = config["organization"]  # noqa: E741
    cert.get_subject().OU = config["organization"]
    cert.get_subject().CN = "lightowl.io"
    cert.get_subject().emailAddress = "contact@lightowl.io"
    cert.set_serial_number(0)
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(315360000)
    cert.set_issuer(cert.get_subject())
    cert.set_pubkey(k)
    cert.sign(k, 'sha512')

    cert = crypto.dump_certificate(crypto.FILETYPE_PEM, cert).decode("utf-8")
    key = crypto.dump_privatekey(crypto.FILETYPE_PEM, k).decode("utf-8")

    with open("/etc/ssl/lightowl/ca.crt", "w") as f:
        f.write(cert)

    with open("/etc/ssl/lightowl/ca.key", "w") as f:
        f.write(key)

    return cert, key


def gen_cert(ca_key, ca_cert, ip_address, commonName):
    '''Create an CERT signed by an given CA'''

    # Generate a CSR
    # http://docs.ganeti.org/ganeti/2.14/html/design-x509-ca.html
    key = crypto.PKey()
    key.generate_key(crypto.TYPE_RSA, 4096)

    req = crypto.X509Req()
    req.get_subject().CN = commonName
    req.set_pubkey(key)
    req.sign(key, "sha512")

    key = crypto.dump_privatekey(crypto.FILETYPE_PEM, key).decode("utf-8")

    ca_cert = crypto.load_certificate(
        crypto.FILETYPE_PEM, bytes(ca_cert, 'utf-8')
    )
    ca_key = crypto.load_privatekey(
        crypto.FILETYPE_PEM, bytes(ca_key, 'utf-8')
    )

    IP_SAN: str = f"IP:{ip_address}"

    # Generate Cert
    cert = crypto.X509()
    cert.set_subject(req.get_subject())
    cert.set_serial_number(random.randint(0, sys.maxsize))
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(1*365*24*60*60)
    cert.add_extensions([crypto.X509Extension(b"subjectAltName", False, bytes(IP_SAN))])
    cert.set_issuer(ca_cert.get_subject())
    cert.set_pubkey(req.get_pubkey())
    cert.sign(ca_key, "sha512")  # Sign with CA

    cert = crypto.dump_certificate(crypto.FILETYPE_PEM, cert).decode("utf-8")

    with open("/etc/ssl/lightowl/server.crt", 'w') as f:
        f.write(cert)

    with open("/etc/ssl/lightowl/server.key", 'w') as f:
        f.write(key)

    with open("/etc/ssl/lightowl/server.pem", "w") as f:
        f.write(f"{cert}{key}")



# if __name__ == "__main__":
#     ca_cert, ca_key = gen_ca("FR", "NORD", "LILLE", "lightowl.io", "lightowl.io", "lightowl.io", "contact&lightowl.io", 0, 0, 315360000)

#     with open("/etc/ssl/lightowl/ca.crt", "w") as f:
#         f.write(ca_cert)
#     with open("/etc/ssl/lightowl/ca.key", "w") as f:
#         f.write(ca_key)

#     cert, key = gen_cert(ca_key=ca_key, ca_cert=ca_cert, commonName="server")

