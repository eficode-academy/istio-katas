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

```sh
kubectl apply -f deploy/v1
kubectl apply -f deploy/v2
```

In another shell, run the following to continously query the sentence service
and observe the effect of deployment changes:

```sh
scripts/loop-query.sh
```



```sh
kubectl apply -f deploy/virtual-service-canary.yaml
```

![Canary Traffic in Kiali][images/kiali-canary.png]



# Cleanup

kubectl delete -f deploy/v1
kubectl delete -f deploy/v2
kubectl delete -f deploy/virtual-service-canary.yaml
