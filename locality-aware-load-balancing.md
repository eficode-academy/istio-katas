# Locality/Topology Aware Load Balancing and Failover


```sh
kubectl apply -f deploy/multitool.yaml
kubectl scale --replicas 2 deploy multitool
```

```sh
kubectl exec -it <POD> -- bash
```

```sh
for ii in {1..20}; do curl multitool; done
```

```sh
kubectl -n istio-system get istiooperator istiocontrolplane -o json | jq .spec.meshConfig.localityLbSetting
```

```sh
kubectl apply -f deploy/multitool-dest-rule.yaml
```

```sh
for ii in {1..20}; do curl multitool; done
```

```sh
kubectl apply -f deploy/multitool-dest-rule-distribute.yaml
```

```sh
for ii in {1..20}; do curl multitool; done
```

# Cleanup

```sh
kubectl delete -f deploy/multitool.yaml
kubectl delete -f deploy/multitool-dest-rule-distribute.yaml
```
