[//]: # (Copyright, Michael Vittrup Larsen)
[//]: # (Origin: https://github.com/MichaelVL/istio-katas)
[//]: # (Tags: #canary-deployment #VirtualService)

# Canary deployments

Blue/green deployments are characterised by an explicit choice of which version
we want to access (e.g. using an HTTP header as we did in the previous
exercises).

When we are satisfies with our blue/green deployments, we might want to expose
the new version to a larger group of users, which are not expected to know how
to route to different versions. We therefore switch to a **statistical
distribution** of traffic, e.g. 1% of our testers are exposed to the new
version.  Simultaneously we observe the state of the new version and when we are
happy about the result we can promote the **Canary version** to be the primary
version.

This exercise show how to implement Canary deployments with Istio.

First, deploy version `v1` and `v2`:

```console
kubectl apply -f deploy/v1
kubectl apply -f deploy/v2
```

In another shell, run the following to continuously query the sentence service
and observe the effect of deployment changes:

```console
scripts/loop-query.sh
```

Currently we observe ordinary Kubernetes service load balancing, i.e. we see
both `v1` and `v2` results.

Apply the following Istio
[VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
to specify that 10% of the traffic should go to `v2`:

```console
kubectl apply -f deploy/virtual-service-canary.yaml
```

Open Kiali, and observe that traffic is routed as expected. Note that the
'display' setting has been set to show 'request percentage':

![Canary Traffic in Kiali](images/kiali-canary-anno.png)

Canary deployments are often combined with logic that combine metrics monitoring
and a gradually increase in the percentage of traffic routed to the test
version. Deployment tools like Spinnaker and ArgoRollout supports such logic.

When we are confident, that `name-v2` is solid, we can promote it to be the
primary version:

```console
kubectl apply -f deploy/virtual-service-canary-promote.yaml
```

and after a short while we will see all traffic flowing to `v2`:

![Canary promoted](images/kiali-canary-promoted.png)

Again, this promotion step would normally be handled automatically by an
continous deployment agent, but we can also do it manually as we did here.

# Cleanup

```console
kubectl delete -f deploy/v1
kubectl delete -f deploy/v2
kubectl delete -f deploy/virtual-service-canary-promote.yaml
```
