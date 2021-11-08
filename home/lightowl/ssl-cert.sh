#!/bin/bash

CERT_COMPANY_NAME=LightOwl
CERT_COUNTRY=FR
CERT_STATE=FRANCE
CERT_CITY=LILLE

CERT_DIR=/etc/ssl/lightowl

ROOT_CERT=ca.pem
ROOT_CERT_KEY=ca.key.pem


# make directories to work from
mkdir -p $CERT_DIR

create_root_cert(){
  # Create your very own Root Certificate Authority
  openssl genrsa \
    -out $CERT_DIR/$ROOT_CERT_KEY \
    2048

  # Self-sign your Root Certificate Authority
  # Since this is private, the details can be as bogus as you like
  openssl req \
    -x509 \
    -new \
    -nodes \
    -key ${CERT_DIR}/$ROOT_CERT_KEY \
    -days 1024 \
    -out ${CERT_DIR}/$ROOT_CERT \
    -subj "/C=$CERT_COUNTRY/ST=$CERT_STATE/L=$CERT_CITY/O=$CERT_COMPANY_NAME Signing Authority/CN=$CERT_COMPANY_NAME Signing Authority"
}


create_domain_cert()
{
  local FQDN=$1
  local FILENAME=${FQDN/\*/wild}
  local CERT_NAME=$2

  # Create a Device Certificate for each domain,
  # such as example.com, *.example.com, awesome.example.com
  # NOTE: You MUST match CN to the domain name or ip address you want to use
  openssl genrsa \
    -out $CERT_DIR/${CERT_NAME}.key \
    2048

  # Create a request from your Device, which your Root CA will sign
  if [[ ! -z "${SAN}" ]]; then
    openssl req -new \
      -key ${CERT_DIR}/${CERT_NAME}.key \
      -out ${CERT_DIR}/${CERT_NAME}.csr \
      -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=$CERT_COMPANY_NAME/CN=${FQDN}" \
      -reqexts san_env -config <(cat /etc/ssl/openssl.cnf <(cat ./openssl-san.cnf))
  else
    openssl req -new \
      -key ${CERT_DIR}/${CERT_NAME}.key \
      -out ${CERT_DIR}/${CERT_NAME}.csr \
      -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=$CERT_COMPANY_NAME/CN=${FQDN}"
  fi

  
  # Sign the request from Device with your Root CA
  if [[ ! -z "${SAN}" ]]; then
    openssl x509 \
      -sha256 \
      -req -in $CERT_DIR/${CERT_NAME}.csr \
      -CA $CERT_DIR/$ROOT_CERT \
      -CAkey $CERT_DIR/$ROOT_CERT_KEY \
      -CAcreateserial \
      -out $CERT_DIR/${CERT_NAME}.crt \
      -days 500 \
      -extensions san_env \
      -extfile openssl-san.cnf
  else
    openssl x509 \
      -sha256 \
      -req -in $CERT_DIR/${CERT_NAME}.csr \
      -CA $CERT_DIR/$ROOT_CERT \
      -CAkey $CERT_DIR/$ROOT_CERT_KEY \
      -CAcreateserial \
      -out $CERT_DIR/${CERT_NAME}.crt \
      -days 500 
  fi
}

 METHOD=$1
 ARGS=${*:2}

echo "Called with $METHOD and $ARGS"
if [ -z "${METHOD}" ]; then
  echo "Usage ./sslcerts.sh [create_root_cert|create_domain_cert] <args>"
  echo "Below are the environment variabls you can use:"
  echo "CERT_COMPANY_NAME=Company Name"
  echo "CERT_COUNTRY=Country"
  echo "CERT_STATE=State"
  echo "CERT_CITY=City"
  echo "CERT_DIR=Directory where certificate needs to be genereated" 
  echo "ROOT_CERT=Name of the root cert"
  echo "ROOT_CERT_KEY=Name of root certificate key"
else
  ${METHOD} ${ARGS}
fi