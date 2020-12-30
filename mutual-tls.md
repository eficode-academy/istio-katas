# Authentication with Mutual TLS

This exercise will demonstrate how to use mutual TLS inside the mesh between
PODs with the Istio sidecar injected and also from mesh-external services
accessing the mesh through an ingress gateway.

## Mutual TLS Inside the Mesh

Deploy the sentences application:

```sh
kubectl apply -f deploy/mtls/
```

Execute `kubectl get pods` and observe that we have one container per POD, i.e. no Istio sidecars injected:

```
NAME                         READY   STATUS    RESTARTS   AGE
age-657d4d9678-q8h7d         1/1     Running   0          3s
name-86969f7468-4qfmp        1/1     Running   0          3s
sentences-779767c659-mlcm9   1/1     Running   0          4s
```

Execute the following to retreive sentences and thus update Istio metrics.

```sh
scripts/loop-query-loadbalancer-ep.sh
```

If we observe the result in Kiali, we will see that we only have information
about traffic from the ingress gateway towards the frontend sentences service
and that mTLS is not being used (later we will see how Kiali denotes that mTLS
is in use and be able to see the difference from this view).:

![Kiali with no sidecars](images/kiali-no-sidecar-no-mtls-anno.png)

We now create a PeerAuthentication settings that require `STRICT` mTLS:

```sh
kubectl apply -f deploy/mtls/peer-auth/strict.yaml
```

We see, that traffic still flows, which is because the sentences services do not
have an Istio sidecar and the strict peer-authentication policy we created only
applies to the namespace where we created it and it is only applied when
validating requests made *towards* a workload with an Istio sidecar. I.e. even
if we created a strict policy in the namespace of the ingress gateway, traffic
would still flow.

Istio lets us define mTLS settings using these resource types:

- `PeerAuthentication` - What a sidecar accepts (ingress)

- `DestinationRule` - what type of TLS sidecar sends (egress)

Lets enable the Istio sidecar for the age service:

```sh
cat deploy/mtls/age.yaml |grep -v inject | kubectl apply -f -
```

After this we see, that traffic no longer flows. This is because the frontend
sentences service do not have an Istio sidecar and hence do not use mTLS towards
the `age` service which now require mTLS.

Inspect the result in Kiali - we see 100% errors:

![Kiali with no sidecars](images/kiali-mtls-error.png)

While migrating an application to full mTLS, it may be useful to start with a
`PERMISSIVE` mTLS mode which allow a mix of mTLS and un-encrypted and
un-authenticated traffic.

Execute the following to restore traffic:

```sh
kubectl apply -f deploy/mtls/peer-auth/permissive.yaml
```

Next, observe the traffic in Kiali and try to explain why we see the disjoint
graph and what the source of the `unknown` traffic could be.

Hint: Which services have sidecars providing metrics for Kiali?

Lets inject Istio sidecars into all sentences services:

```sh
cat deploy/mtls/*.yaml |grep -v inject | kubectl apply -f -
```

Now we can see in Kiali, that mTLS is enabled between all services of the
sentences application (in the view below, the link between the frontend and the
`age` service has been selected):

![Full mTLS](images/kiali-mtls-anno.png)

To show how we can control egress mTLS settings with a DestinationRule, we
create one that use mTLS towards `v2` of the `name` service and no mTLS for
`v1`:

```sh
kubectl apply -f deploy/mtls/dest-rule/name.yaml
```

Note, that a DestinationRule *will not* take effect until a route rule
explicitly sends traffic to the subset, hence in `deploy/mtls/dest-rule.yaml` we
also define a VirtualService which routes to the subsets.

Now we see a missing padlock on the traffic towards `v1`:

![No mTLS towards v1](images/kiali-mtls-destrule-anno.png)


## Mutual TLS from External Clients through Ingress Gateways


## Cleanup

```sh
kubectl delete -f deploy/mtls/peer-auth/permissive.yaml
kubectl delete -f deploy/mtls/
```
