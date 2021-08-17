#! /bin/bash

set -e

INGRESSGATEWAY_NS="istio-ingress"
PREFIX=${1:-"istio"}
NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
CA="eficode.academy"

touch ~/.rnd

echo "Generating CA: $CA"
openssl req -x509 -sha256 -nodes -days 365 \
    -newkey rsa:2048 \
    -subj "/O=example Inc./CN=$CA" \
    -keyout "$CA.key" \
    -out "$CA.crt"

echo "Creating CSR: $NAMESPACE.sentences.$PREFIX.$CA.csr"
openssl req -out "$NAMESPACE.sentences.$PREFIX.$CA.csr" \
    -newkey rsa:2048 -nodes \
    -keyout "$NAMESPACE.sentences.$PREFIX.$CA.key" \
    -subj "/CN=$NAMESPACE.sentences.$PREFIX.$CA/O=ACMEorg"

echo "Signing CSR and creating cert: $NAMESPACE.sentences.$PREFIX.$CA.crt"
openssl x509 -req -days 365 \
    -CA "$CA.crt" \
    -CAkey "$CA.key" \
    -set_serial 0 \
    -in "$NAMESPACE.sentences.$PREFIX.$CA.csr" \
    -out "$NAMESPACE.sentences.$PREFIX.$CA.crt"

echo "Creating Client CSR: $NAMESPACE.client.$PREFIX.$CA.csr"
openssl req -out "$NAMESPACE.client.$PREFIX.$CA.csr" \
    -newkey rsa:2048 -nodes \
    -keyout "$NAMESPACE.client.$PREFIX.$CA.key" \
    -subj "/CN=$NAMESPACE.client.$PREFIX.$CA/O=ACMEorg"

echo "Signing CSR and creating cert: $NAMESPACE.client.$PREFIX.$CA.csr"
openssl x509 -req -days 365 \
    -CA "$CA.crt" \
    -CAkey "$CA.key" \
    -set_serial 1 \
    -in "$NAMESPACE.client.$PREFIX.$CA.csr" \
    -out "$NAMESPACE.client.$PREFIX.$CA.crt"

echo "Generating kubernetes secret"

kubectl -n $INGRESSGATEWAY_NS create secret generic "$NAMESPACE-sentences-tls-secret" \
    --from-file=cert="$NAMESPACE.sentences.$PREFIX.$CA.crt" \
    --from-file=key="$NAMESPACE.sentences.$PREFIX.$CA.key" \
    --from-file=cacert="$CA.crt"
