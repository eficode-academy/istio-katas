# Authorization - HTTP Network Policies

```console
kubectl apply -f deploy/authz/sentences.yaml
```

```console
scripts/loop-query.sh
```

[Debugging with Ephemeral Containers](debugging-with-ephemeral-containers.md)

```console
kubectl debug -it `kubectl get po -l mode=age -o jsonpath='{.items[0].metadata.name}'` --image praqma/network-multitool -- bash
```

```console
curl name:5000/
```

Additionally, the `name` service have a few other ULRs/endpoints we can access:

```console
curl name:5000/choices
curl name:8000/metrics
```

This shows, that we can access the `name` service from the `age` service, which
is not necessary for the functioning of the sentences application.

## Restricting Access with NetworkPolicies

To restrict inter-service access, we can use this Kubernetes-native
NetworkPolicy:

> Note: Not all Kubernetes Network types implements NetworkPolicy. E.g. the *Flannel* network does not, whereas *Calico* and *WeaveNet* does.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-sentences-to-name
spec:
  podSelector:
    matchLabels:
      app: sentences
      mode: name
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: sentences
          mode: sentence
    ports:
    - port: 5000
      protocol: TCP

```

This policy applies to the `name` service PODs due to the labels given in
`spec.podSelector` and it allows ingress from the `sentence` service due to the
labels and port given in `spec.ingress`.

Apply this with:

```console
kubectl apply -f deploy/authz/networkpolicy.yaml
```

Note, that the default action with Kubernetes NetworkPolicy is:

- If there is no NetworkPolicy that apply to a given POD, then allow any traffic to that POD.

- If there is any NetworkPolicy that apply to a given POD, then there must exist
  a policy that allow traffic, otherwise traffic is denied.

This is implemented by the network solution in Kubernetes - typically by
translating the labels into IP addresses and TCP/UDP ports which are then
programmed into the IP tables of the underlying OS. The Kubernetes NetworkPolicy
is operating at the L3 and L4 networking layers.

This is why allowing the `sentences` service access to the `name` service blocks
all access from the `age` service.

The `sentences` service still have access to the `name` service, which we can
test with an ephemeral debug container in the `sentences` service:

```console
kubectl debug -it `kubectl get po -l mode=sentence -o jsonpath='{.items[0].metadata.name}'` --image praqma/network-multitool -- bash
```

With this command, the previous URLs/endpoints for the `name` service towards
port 5000 will work. The NetworkPolicy did not allow access to port 8000, hence
access the to metrics are no longer allowed.

The `sentences` service can still access the `name:5000/choices` even though
this is not needed by the `sentences` service. However, with a Kubernetes
NetworkPolicy we cannot specify policies on URLs since these policies are
operating at L3/L4 (IP addresses and ports). For this we need an Istio
AuthorizationPolicy which understand L7 (HTTP).

Before continuing, delete the Kubernetes NetworkPolicy:

```console
kubectl delete -f deploy/authz/networkpolicy.yaml
```

## Restricting Access with Istio AuthorizationPolicy



```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-sentences-to-name
spec:
  selector:
    matchLabels:
      app: sentences
      mode: name
  action: ALLOW
  rules:
   - from:
      - source:
          principals: ["cluster.local/ns/$NAMESPACE/sa/sentences"]
     to:
      - operation:
          methods: ["GET"]
          paths: ["/"]

```



No selector means this AuthorizationPolicy will apply to all PODs in the
namespace in which it is created.

```console
export NAMESPACE=default
cat deploy/authz/authz-policy.yaml | envsubst
```

```console
cat deploy/authz/authz-policy.yaml | envsubst | kubectl apply -f -
```


# Cleanup

```console
kubectl delete -f deploy/authz/sentences.yaml
cat deploy/authz/authz-policy.yaml | envsubst | kubectl delete -f -
```
