[//]: # (Author: Michael Vittryp Larsen)
[//]: # (Source: https://github.com/MichaelVL/istio-katas)
[//]: # (Tags: #authorization #epehemeral-containers #NetworkPolicies #AuthorizationPolicy #workload-identity)

# Authorization - HTTP Network Policies

This exercise will demonstrate how to authorize access between components of our
application such that services only have the access they need, not more. This is
the *least privelege security principle*.

Deploy the sentences application:

```console
kubectl apply -f deploy/authz/sentences.yaml
```

and test access:

```console
scripts/loop-query.sh
```

The sentences application is now deployed without any restrictions between components.

To demonstrate that there are no restrictions between services, we access the
`name` service from the `age` service - an access that is not necessary for the
functioning of the sentences application. We use an ephemeral debug container as
described in [Debugging with Ephemeral
Containers](debugging-with-ephemeral-containers.md) to demonstrate this.

Create a debug container attached to the `age` service as follows:

```console
kubectl debug -it `kubectl get po -l mode=age -o jsonpath='{.items[0].metadata.name}'` --image praqma/network-multitool -- bash
```

First we access the primary endpoint of the `name` service. Run the following
command in the debug container terminal:

```console
curl name:5000/
```

Additionally, the `name` service have a few other ULRs/endpoints we can access:

```console
curl name:5000/choices
curl name:8000/metrics
```

This shows, that we have wide access to the `name` service from the `age`
service, which is not necessary for the functioning of the sentences
application.

## Restricting Access with NetworkPolicies

To restrict inter-service access to only what is necessary, we can use this
Kubernetes-native NetworkPolicy:

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

> Note: Not all Kubernetes Network types implements NetworkPolicy. E.g. the *Flannel* network does not, whereas *Calico* and *WeaveNet* does.

This policy applies to the `name` service PODs due to the labels given in
`spec.podSelector` and it allows ingress from the `sentence` service due to the
labels and port given in `spec.ingress`.

Apply this with:

```console
kubectl apply -f deploy/authz/networkpolicy.yaml
```

Retry the `curl` commands from previously and observe that this policy blocks
access from the `age` service to the `name` service.

<details>
  <summary>Why does applying an `ALLOW` policy between the `sentences` service and the `name` service block the `age` service?</summary>

Kubernetes NetworkPolicy applies like this:

- If there is no NetworkPolicy that apply to a given POD, then allow any traffic to that POD.

- If there is any NetworkPolicy that apply to a given POD, then there must exist
  a policy that allow traffic, otherwise traffic is denied.

This is implemented by the network solution in Kubernetes - typically by
translating the labels into IP addresses and TCP/UDP ports which are then
programmed into the IP tables of the underlying OS. The Kubernetes NetworkPolicy
is operating at the L3 and L4 networking layers.

This is why allowing the `sentences` service access to the `name` service blocks
all access from the `age` service.
</details>

The `sentences` service still have access to the `name` service, which we can
test with an ephemeral debug container in the `sentences` service:

```console
kubectl debug -it `kubectl get po -l mode=sentence -o jsonpath='{.items[0].metadata.name}'` --image praqma/network-multitool -- bash
```

With this command, the previous URLs/endpoints for the `name` service towards
port 5000 will work. The NetworkPolicy did not allow access to port 8000, hence
access the to the `name:8000/metrics` endpoint is no longer allowed.

The `sentences` service can still access the `name:5000/choices` URL even though
this is not needed by the `sentences` service. However, with a Kubernetes
NetworkPolicy we cannot specify policies on URLs since these policies are
operating at L3/L4 (IP addresses, L4 protocols and ports). For this we need an
Istio
[AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
which understand L7 (HTTP).

Before continuing, delete the Kubernetes NetworkPolicy:

```console
kubectl delete -f deploy/authz/networkpolicy.yaml
```

## Restricting Access with Istio AuthorizationPolicy

A feature of Istio is strong workload identities. Istio implements the
[SPIFFE](https://spiffe.io) standard and provides cryptographic verifiable
identities to workloads within the mesh.

**These identities are the foundation for authorization and mTLS between
  services.**

Istio bootstraps trust through Kubernetes service accounts since these can be
validated through the Kubernetes certificate authority. **This also means that
there is a 1:1 link between Kubernetes service accounts and workload identities
in Istio.** PODs in Kubernetes sharing a service account share a workload
identity. It is therefore essential, that services to which we want to apply
different policies are assigned different service accounts. For this purpose,
the sentences application we deployed (`deploy/authz/sentences.yaml`) created
three different service accounts, one for each of the `sentences`, `age` and
`name` service.

With different identities assigned to the three services, we can create an
`ALLOW` Istio
[AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
that applies to the `name` service (due to the label selector in
`spec.selector.matchLabels`):

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

Note how the policy allow traffic from an workload identified as
`cluster.local/ns/$NAMESPACE/sa/sentences`. This identifier should be interpreted as:

```
cluster.local    - Identity within this cluster (identity can extend outside a Kubernetes cluster)
ns               - Scoped to a namespace
$NAMESPACE       - The name of our namespace (we will expand this env. variable later)
sa               - Scoped to a service account
sentences        - The name of the service account
```

If we inspect the service accounts with `kubectl get sa`, we will see:

```
NAME        SECRETS   AGE
age         1         4s
default     1         33m
name        1         4s
sentences   1         4s
```

I.e. we have three service accounts created as part of the sentences application
and a `default` that was created together with the namespace.

Similarly, we can get the service account used by the `sentences` service as follows:

```console
kubectl get po -l mode=sentence -o jsonpath='{.items[*].spec.serviceAccount}'
```

To allow for running this exercise in different environments, the namespace name
has been made configurable. To inspect the resulting AuthorizationPolicy use the
following commands and change the value of `NAMESPACE` to suit your environment:

```console
export NAMESPACE=default
cat deploy/authz/authz-policy.yaml | envsubst
```

And apply the policy:

```console
cat deploy/authz/authz-policy.yaml | envsubst | kubectl apply -f -
```

If we retry the curl commands from previously from both the `age` and
`sentences` service, we will see that the only access that is now possible is
the `sentences` service accessing the primary `name` endpoint and the
`name:5000/choices` endpoint cannot be accessed either. This correlates with the
AuthorizationPolicy only allowing `GET` towards `/`.

Istio AuthorizationPolicy also allow assigning conditions to policies and this
can be used to implement validation that e.g. only authenticated users access a
given service.

# Cleanup

```console
kubectl delete -f deploy/authz/sentences.yaml
cat deploy/authz/authz-policy.yaml | envsubst | kubectl delete -f -
```
