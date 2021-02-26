#! /bin/bash

set -e

OPT_HEADER=${1:-""}
NODEIP=$(kubectl get no -o jsonpath='{.items[0].status.addresses[0].address}')
PORT=$(kubectl get svc sentences -o jsonpath='{.spec.ports[0].nodePort}')

if [[ $OPT_HEADER == Authorization* ]]; then
    echo "Using $NODEIP:$PORT, header 'Authorization <REDACTED>'"
else
    echo "Using $NODEIP:$PORT, header '$OPT_HEADER'"
fi

if [ -z "$OPT_HEADER" ]; then
    curl $NODEIP:$PORT; echo ""
else
    curl -H "$OPT_HEADER" $NODEIP:$PORT; echo ""
fi
