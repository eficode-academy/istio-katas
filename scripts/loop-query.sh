#! /bin/bash

set -e

OPT_HEADER=${1:-""}
#NODEIP=$(kubectl get no -o jsonpath='{.items[0].status.addresses[0].address}')
#PORT=$(kubectl get svc sentences -o jsonpath='{.spec.ports[0].nodePort}')

echo "Using $NODEIP:$PORT, header '$OPT_HEADER'"

IFS='' read -ra ADDR <<< "$OPT_HEADER"

for i in $(seq 1 10000); do
    sleep 0.3;
    if [ -z "$OPT_HEADER" ]; then
        curl $NODEIP:$PORT; echo ""
    else
        curl "$OPT_HEADER" $NODEIP:$PORT; echo ""
    fi
done
