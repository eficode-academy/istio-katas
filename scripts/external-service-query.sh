#! /bin/bash

set -e

ARG_PATH=${1:-"http://httpbin.org"}

MULTITOOL_POD=$(kubectl get pod -l app=multitool -o jsonpath='{.items..metadata.name}')

echo "Using $MULTITOOL_POD to query $ARG_PATH"

for i in $(seq 1 10000); do
    sleep 0.3;    
    kubectl exec "$MULTITOOL_POD" -c network-multitool -- curl -sI "$ARG_PATH" | grep  "HTTP/"
done
