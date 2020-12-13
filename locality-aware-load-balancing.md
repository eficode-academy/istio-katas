# Locality/Topology Aware Load Balancing and Failover

```sh
kubectl get nodes --show-labels
```

```
NAME       STATUS   LABELS
node-1     Ready    topology.kubernetes.io/region=eu-central-1,topology.kubernetes.io/zone=zone-a
node-2     Ready    topology.kubernetes.io/region=eu-central-1,topology.kubernetes.io/zone=zone-b
```

```sh
kubectl apply -f deploy/multitool-readiness-probe.yaml
kubectl scale --replicas 4 deploy multitool
```

```
NAME                        READY   STATUS    RESTARTS   AGE     IP              NODE
multitool-5cfbd5449-g7phn   1/2     Running   0          111s    10.244.36.133   node-1
multitool-5cfbd5449-q5gwt   1/2     Running   0          112s    10.244.36.134   node-1
multitool-5cfbd5449-2pb8r   1/2     Running   0          111s    10.244.61.202   node-2
multitool-5cfbd5449-w6x7w   1/2     Running   0          2m12s   10.244.61.201   node-2
```

```sh
kubectl exec -it <POD on node-1> -- bash
```

```sh
touch /tmp/ready
```

```sh
for ii in {1..20}; do curl multitool; done
```

```sh
kubectl exec -it <POD on node-2> -- touch /tmp/ready
```

```sh
kubectl -n istio-system get istiooperator istiocontrolplane -o json | jq .spec.meshConfig.localityLbSetting
```

```
{
  "enabled": true
}
```

```sh
kubectl apply -f deploy/multitool-dest-rule.yaml
```

```sh
for ii in {1..20}; do curl multitool; done
```

```sh
kubectl exec -it <Other POD on node-1> -- touch /tmp/ready
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
