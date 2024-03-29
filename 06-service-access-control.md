[//]: # (Copyright, Eficode )
[//]: # (Origin: https://github.com/eficode-academy/istio-katas)
[//]: # (Tags: #authorization #epehemeral-containers #NetworkPolicies #AuthorizationPolicy #workload-identity)

# Service Access Control


## Learning goal

- Access control - Kubernetes NetworkPolicies
- Access control - Istio AuthorizationPolicy

## Introduction

This exercise will demonstrate how to authorize access between components of our
application such that services only have the access they need, not more. This is
the *least privilege security principle*.

First you will control service to service access with native kubernetes
network policies to understand what is possible and what is not.

Then you will use a Istio custom resource
definition([CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/))
to understand what Istio functionality can be used to control service
to service access. The Istio CRD for this is the
[AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/).

> :bulb: If you have not completed exercise
> [00-setup-introduction](00-setup-introduction.md) you **need** to label
> your namespace with `istio-injection=enabled`.

## Exercise

### Overview

A general overview of what you will be doing in the **Step By Step** section.

- Deploy sentences application services

- Test access between services

- Restrict access to the name service with a kubernetes NetworkPolicy

- Test access between services

- Restrict access with an Istio AuthorizationPolicy

- Test access between services

### Step by Step

Expand the **Tasks** section below to do the exercise.

<details>
    <summary> Tasks </summary>

#### Task: Deploy sentences application services

___


Deploy the sentences application:

```console
kubectl apply -f 06-service-access-control/start/
```

and test access:

```console
scripts/loop-query.sh
```

#### Task: Test access to `name` service from `age` service

___


The sentences application is now deployed without any restrictions between
components.

To demonstrate that there are no restrictions between services, we access the
`name` service from the `age` service - an access that is **not necessary** for the
functioning of the sentences application.

Export `age` services POD name to an environment variable.

```console
export AGE_POD=$(kubectl get pod -l app=sentences -l mode=age -o jsonpath="{.items[0].metadata.name}")
```

First we access the primary endpoint of the `name` service. Run the following
command.

```console
kubectl exec $AGE_POD -c age -- curl --silent name:5000/; echo "";
```

Additionally, the `name` service have a few other ULRs/endpoints we can access:

```console
kubectl exec $AGE_POD -c age -- curl --silent name:5000/choices; echo "";
```

```console
kubectl exec $AGE_POD -c age -- curl --silent name:8000/metrics; echo "";
```

This shows, that we have wide access to the `name` service from the `age`
service, which is not necessary for the functioning of the sentences
application.

#### Task: Pull the sentences application services down

___

First pull all the services down.

```console
kubectl delete -f 06-service-access-control/start/
```

#### Task: Restrict access to the name service with a kubernetes NetworkPolicy

___


To restrict inter-service access to only what is necessary create a file
called `name-network-policy.yaml` in the directory
`06-service-access-control/start/`.

Paste in the following yaml.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-sentences-to-name
  namespace: $STUDENT_NS
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

> Note: Not all Kubernetes Network types implements NetworkPolicy.
> E.g. the *Flannel* network does not, whereas *Calico* and *WeaveNet* does.

This policy applies to the `name` service PODs due to the labels given in
`spec.podSelector` and it allows ingress from the `sentence` service due to the
labels and port given in `spec.ingress`.

#### Task: Redeploy the sentences application services

___

Now that you have a network policy redeploy the sentences application services
along with the policy by substituting the placeholders with environment variable(s)
and applying with kubectl.

```console
for file in 06-service-access-control/start/*.yaml; do envsubst < $file | kubectl apply -f -; done
```

Once all services are running test that the sentences application is running properly.

```console
scripts/loop-query.sh
```

#### Task: Test access to `name` service from `age` service

___

Export `age` services POD name to an environment variable.

```console
export AGE_POD=$(kubectl get pod -l app=sentences -l mode=age -o jsonpath="{.items[0].metadata.name}")
```

Retry the `curl` commands from previously and observe that this policy blocks
access from the `age` service to the `name` service.

```console
kubectl exec $AGE_POD -c age -- curl --silent name:5000/; echo "";
```

```console
kubectl exec $AGE_POD -c age -- curl --silent name:5000/choices; echo "";
```

```console
kubectl exec $AGE_POD -c age -- curl --silent name:8000/metrics; echo "";
```

<details>
  <summary>Why does applying an `ALLOW` policy between the `sentences` service and the `name` service block the `age` service from accessing the `name` service?</summary>

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

#### Task: Test access to `name` service from the `sentences` service

___


The `sentences` service still has access to the `name` service, which we can
test by executing a curl command from the container in the `sentences`
service as you have done for the age container.

Export `sentences` services POD name to an environment variable.

```console
export SENTENCES_POD=$(kubectl get pod -l app=sentences -l mode=sentence -o jsonpath="{.items[0].metadata.name}")
```

Access the primary endpoint of the `name` service. by running the following
command.

```console
kubectl exec $SENTENCES_POD -c sentences -- curl --silent name:5000/; echo "";
```

With this command, the previous URLs/endpoints for the `name` service towards
port 5000 will work. The NetworkPolicy **did not allow access to port 8000**.
So access the to the `name:8000/metrics` endpoint is no longer allowed.

The `sentences` service can still access the `name:5000/choices` URL even though
this is not needed by the `sentences` service.

Execute the following command.

```console
kubectl exec $SENTENCES_POD -c sentences -- curl --silent name:5000/choices; echo "";
```

With a Kubernetes NetworkPolicy we cannot specify policies on URLs since these
policies are operating at L3/L4 (IP addresses, L4 protocols and ports). For this
we need an Istio
[AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
which understands L7 (HTTP).

#### Task: Restrict access with an Istio AuthorizationPolicy

___


A feature of Istio is strong workload identities. Istio implements the
[SPIFFE](https://spiffe.io) standard and provides cryptographic verifiable
identities to workloads within the mesh.

> These identities are the foundation for authorization and mTLS between
> services.

Istio bootstraps trust through Kubernetes service accounts since these can
be validated through the Kubernetes certificate authority. **This also means
that there is a 1:1 link between Kubernetes service accounts and workload
identities in Istio.**

PODs in Kubernetes sharing a service account share a workload identity.
It is therefore **essential**, that services to which we want to apply
different policies are assigned different service accounts. For this
purpose, the sentences application we deployed created **three**
different service accounts, one for each of the `sentences`, `age` and
`name` service.

With different identities assigned to the three services,
we can create an `ALLOW` Istio
[AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
that applies to the `name` service (due to the label selector in
`spec.selector.matchLabels`).

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
          principals: ["cluster.local/ns/$STUDENT_NS/sa/sentences"]
     to:
      - operation:
          methods: ["GET"]
          paths: ["/"]

```

Note how the policy allows traffic from a workload identified as
`cluster.local/ns/$STUDENT_NS/sa/sentences`. This identifier should be
interpreted like:

```
cluster.local    - Identity within this cluster (identity can extend outside a Kubernetes cluster)
ns               - Scoped to a namespace
$STUDENT_NS      - The name of our namespace (we will expand this env. variable later)
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
following commands and change the value of `STUDENT_NS` to `<YOUR_NAMESPACE>`, e.g
student1, student2, etc.

Examine the substitution of the placeholder with the environment variable.

```console
cat 06-service-access-control/examples/authz-policy.yaml | envsubst
```

And apply the policy:

```console
cat 06-service-access-control/examples/authz-policy.yaml | envsubst | kubectl apply -f -
```

If we retry the curl commands from previously from both the `age` and
`sentences` service, we will see:

- That the only access that is now possible is the `sentences` service accessing the
primary `name` endpoint.
- The `name:5000/choices` endpoint cannot be accessed either. This correlates with the
AuthorizationPolicy only allowing `GET` towards `/`.

> :bulb: Note that it might take a few seconds for the policy to properly register.

```console
kubectl exec $SENTENCES_POD -c sentences -- curl --silent name:5000/choices; echo "";
```

</details>

## Summary

The main takeaways from this exercise are.

- Kubernetes NetworkPolicy's are operating at L3/L4 networking layers

- Istio AuthorizationPolicy's understand L7 networking layer

- Istio bootstraps trust through Kubernetes service accounts. This  means
that there is a 1:1 link between Kubernetes service accounts and workload
identities in Istio.

Istio AuthorizationPolicy also allows assigning conditions to policies. This
can be used to implement validation that e.g. only authenticated users access a
given service.

## Cleanup

```console
kubectl delete -f 06-service-access-control/start/
cat 06-service-access-control/examples/authz-policy.yaml | envsubst | kubectl delete -f -
```
