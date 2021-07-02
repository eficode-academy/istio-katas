#! /bin/bash

set -e

GATEWAY_HOST=""
OPT_HEADER=""

while getopts ":g:h:" arg; do
  case $arg in
    g)
      GATEWAY_HOST=$OPTARG
      ;;
    h)
      OPT_HEADER=$OPTARG
      ;;
  esac
done


if [ -z "$GATEWAY_HOST" ]; then
  NODEIP=$(kubectl get no -o jsonpath='{.items[0].status.addresses[0].address}')
  PORT=$(kubectl get svc sentences -o jsonpath='{.spec.ports[0].nodePort}')
  
  echo "Using $NODEIP:$PORT, header '$OPT_HEADER'"
  for i in $(seq 1 10000); do
    sleep 0.3;
    if [ -z "$OPT_HEADER" ]; then
      curl $NODEIP:$PORT; echo ""
    else
      curl -H "$OPT_HEADER" $NODEIP:$PORT; echo ""
    fi
  done
else
  echo "Using $GATEWAY_HOST, header '$OPT_HEADER'"
  for i in $(seq 1 10000); do
    sleep 0.3;
    if [ -z "$OPT_HEADER" ]; then
      curl $GATEWAY_HOST; echo ""
    else
      curl -H "$OPT_HEADER" $GATEWAY_HOST; echo ""
    fi
  done
fi
