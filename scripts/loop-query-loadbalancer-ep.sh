#! /bin/bash

set -e

ARG_PROTO=${1:-"http"}
ARG_PATH=${2:-""}

CURL_OPTS=""

INGRESS_GW_LABEL="app=istio-ingressgateway"
if [ $ARG_PROTO == "https+mtls" ]; then
  PROTO="https"
  PORT=443
  CA="example.com.crt"
  CLIENT_CERT="client.example.com.crt"
  CLIENT_KEY="client.example.com.key"
  CURL_OPTS="--cacert $CA --cert $CLIENT_CERT --key $CLIENT_KEY"
elif [ $ARG_PROTO == "https" ]; then
  PROTO="https"
  PORT=443
  CA="example.com.crt"
  CURL_OPTS="--cacert $CA"
else
  PROTO="http"
  PORT=80
fi
HOST="sentences.istio.eficode.academy"

URL_PATH="/$ARG_PATH"

echo "Using ingress gateway with label: $INGRESS_GW_LABEL"
#LBIP=$(kubectl -n istio-system get svc -l $INGRESS_GW_LABEL -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
#echo " = $LBIP"

URL="$PROTO://$HOST:$PORT$URL_PATH"
CURL_OPTS="--resolve $HOST:$PORT $CURL_OPTS"
echo "Using curl options: '$CURL_OPTS'"
echo "Using URL: $URL"

for i in $(seq 1 10000); do
    sleep 0.3;
    curl $CURL_OPTS $URL; echo ""
done
