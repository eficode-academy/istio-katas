# Observing Delays

First, deploy version `v1`, `v2` and `v3`:

```sh
kubectl apply -f deploy/v1
kubectl apply -f deploy/v2
kubectl apply -f deploy/v3
```

```sh
scripts/loop-query.sh
```

![Canary Traffic in Kiali](images/kiali-request-delays-anno.png)


# Cleanup

kubectl delete -f deploy/v1
kubectl delete -f deploy/v2
kubectl delete -f deploy/v3
