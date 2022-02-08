#! /bin/bash

set -e

ARG_PROTO=${1:-"http"}
ARG_PATH=${2:-""}
PREFIX=${TRAINING_NAME:-istio}
NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
CA="eficode.academy"
HOST="$NAMESPACE.sentences.$PREFIX.eficode.academy"
INGRESS_GW_LABEL="app=istio-ingressgateway"
CURL_OPTS=""

if [ $ARG_PROTO == "https+mtls" ]; then
  PROTO="https"
  PORT=443
  CLIENT_CERT="$NAMESPACE.client.$PREFIX.$CA.crt"
  CLIENT_KEY="$NAMESPACE.client.$PREFIX.$CA.key"
  CURL_OPTS="--cacert $CA.crt --cert $CLIENT_CERT --key $CLIENT_KEY"
elif [ $ARG_PROTO == "https" ]; then
  PROTO="https"
  PORT=443
  CURL_OPTS="--cacert $CA.crt"
else
  PROTO="http"
  PORT=80
fi

URL_PATH="/$ARG_PATH"
URL="$PROTO://$HOST:$PORT$URL_PATH"
CURL_OPTS="--resolve $HOST:$PORT $CURL_OPTS"
echo "-------------------------------------"
echo "Using ingress gateway with label: $INGRESS_GW_LABEL"
echo "Using URL: $URL"
echo "Using curl options: '$CURL_OPTS'"
echo "-------------------------------------"

for i in $(seq 1 10000); do
    sleep 0.3;
    curl $CURL_OPTS $URL; echo ""
done
