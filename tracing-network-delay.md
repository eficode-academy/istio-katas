# Investigate Network Delay with Distributed Tracing

First, deploy version `v1` of the test application:

```sh
kubectl apply -f deploy/v1
```

```sh
scripts/loop-query.sh
```

```sh
kubectl apply -f deploy/virtual-service-age-delay.yaml
```

![Network delay in in Jaeger][images/jaeger-network-delay.png]


# Cleanup

kubectl delete -f deploy/v1
kubectl delete -f deploy/virtual-service-age-delay.yaml
