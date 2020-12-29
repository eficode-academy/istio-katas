#! /bin/bash

set -e

ARG_PROTO=$1
ARG_PATH=$2

CURL_OPTS=""

INGRESS_GW_LABEL="app=istio-ingressgateway"
if [ $ARG_PROTO == "https" ]; then
  PROTO="https"
  PORT=443
  CA="example.com.crt"
  CURL_OPTS="--cacert $CA"
else
  PROTO="http"
  PORT=80
fi
HOST="sentences.example.com"

URL_PATH="/"
if [ ! -z $ARG_PATH ]; then
    URL_PATH="/$ARG_PATH"
fi

echo "Using ingress gateway with label: $INGRESS_GW_LABEL"
LBIP=$(kubectl -n istio-system get svc -l $INGRESS_GW_LABEL -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
echo " = $LBIP"

URL="$PROTO://$HOST:$PORT$URL_PATH"
CURL_OPTS="--resolve $HOST:$PORT:$LBIP $CURL_OPTS"
echo "Using curl options: '$CURL_OPTS'"
echo "Using URL: $URL"

for i in $(seq 1 10000); do
    sleep 0.3;
    curl $CURL_OPTS $URL; echo ""
done
