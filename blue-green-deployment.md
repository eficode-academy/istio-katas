# Blue/green deployments

First, deploy version `v1`:

```sh
kubectl apply -f deploy/v1
```

This created three deployments with associated services. After deployment you shouid see:

```sh
kubectl get po,svc
NAME                             READY   STATUS    RESTARTS   AGE
pod/age-79475c5566-5677k         2/2     Running   0          2m18s
pod/name-v1-dfcb76bdf-8lbc4      2/2     Running   0          2m18s
pod/sentences-7d9cc5c899-sms7j   2/2     Running   0          2m17s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/age          ClusterIP   10.106.5.47      <none>        5000/TCP         2m18s
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          39m
service/name         ClusterIP   10.97.114.150    <none>        5000/TCP         2m18s
service/name-v1      ClusterIP   10.107.209.9     <none>        5000/TCP         2m18s
service/sentences    NodePort    10.110.120.194   <none>        5000:32005/TCP   2m17s
```

In another shell, run the following to continuously query the sentence service
and observe the effect of deployment changes:

```sh
scripts/loop-query.sh
```

The `sentences` service will query the `name` Kubernetes service to retrieve a
name. This `name` service does not include a `version` label in its selectors,
i.e. when we deploy version `v2` with the following command, we will see names
returned from both versions of the `name` service

```sh
kubectl apply -f deploy/v2
```

> Try inspect the Kubernetes services `name`, `name-v1` and `name-v2` to see how they differ in their label selectors.

## Header Based Routing

Next we will configure our Istio service mesh to route traffic to the two
different version through the Kubernetes services `name-v1` and `name-v2`. Since
our aim is blue/green deployment, we want to be able to deliberately choose
which version of `name` we use, however, since we only access the `name` service
indirectly through `sentences` we need some way of communicating this
information. We does this through [HTTP headers](https://en.wikipedia.org/wiki/List_of_HTTP_header_fields).

In particular we will use the header `x-test` to indicate our version
preference. Use the following command to continuously run a query against the
sentence service with this header set to the value of `use-v2`:


```sh
scripts/loop-query.sh 'x-test: use-v2'
```

To configure routing in the Istio service mesh based on the `x-test` header
apply the following Istio `VirtualService` resource:

```sh
kubectl apply -f deploy/virtual-service-svc-based.yaml
```

Inspect the file `deploy/virtual-service-svc-based.yaml` to see how routing
towards the host `name` is directed to either the service `name-v1` or `name-v2`
based on the content of the header `x-test`. More info about Istio [Virtual
Service can be found
here](https://istio.io/latest/docs/reference/config/networking/virtual-service).

This exercise showed how a Istio
[VirtualService](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
could be used to modify routing from a host `name` to alternative hosts
`name-v1` and `name-v2` with the hosts being represented by Kubernetes
services. This is however, not limited to Kubernetes services and this approach
could be used for other service types, including services external to
Kubernetes.

# Cleanup

```sh
kubectl delete -f deploy/v1
kubectl delete -f deploy/v2
kubectl delete -f deploy/virtual-service-svc-based.yaml
```