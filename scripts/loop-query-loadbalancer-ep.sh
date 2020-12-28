#! /bin/bash

set -e

INGRESS_GW_LABEL="app=istio-ingressgateway"
if [ $1 == "https" ]; then
  PROTO="https"
  PORT=443
else
  PROTO="http"
  PORT=80
fi
HOST="sentences.example.com"
CA="example.com.crt"

echo "Using ingress gateway with label: $INGRESS_GW_LABEL"
LBIP=$(kubectl -n istio-system get svc -l $INGRESS_GW_LABEL -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
echo " = $LBIP"

CURL_OPTS="--cacert $CA --resolve $HOST:$PORT:$LBIP"
echo "Using curl options: '$CURL_OPTS'"
echo "Using ingress endpoint: $PROTO://$HOST:$PORT"

for i in $(seq 1 10000); do
    sleep 0.3;
    curl $CURL_OPTS $PROTO://$HOST:$PORT; echo ""
done
