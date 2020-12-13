# Locality/Topology Aware Load Balancing and Failover

This exercise will demonstrate how Istio routing is aware of the topology of the
infrastructure. Infrastructure topology refers to the fact, that certain
components in an infrastructure will share other components, and if those
components fail, both the dependent components will fail. E.g. two VMs scheduled
to the same physical server will both fail if the physical server fail. The same
applies to networking, switches, routers, poser supplies etc.

In highly available (HA) infrastructures we architect the infrastructure with
the topology in mind, and configuring Istio routing is part of this.

For availability reasons we want to load balance traffic across all regions and
zones, but for cost and latency reasons we want to keep traffic local to regions
and zone. Istio allows us to configure the balance we desire between these
conflicting requirements.

In a Kubernetes cluster nodes are labeled according to the region and zone in
which they are located.

```sh
kubectl get nodes --show-labels
```

```
NAME       STATUS   LABELS
node-1     Ready    topology.kubernetes.io/region=eu-central-1,topology.kubernetes.io/zone=zone-a
node-2     Ready    topology.kubernetes.io/region=eu-central-1,topology.kubernetes.io/zone=zone-b
```

A region will have a number of zones, and the example above show that our
cluster is located in a single region (very common with Kubernetes clusters),
but with nodes in two zone (two or more are typical for HA clusters).

Kubernetes use readiness probes to detect when PODs are ready to serve network
traffic. In this exercise we will use a deployment where we manually can control
POD readiness. Run the following commands to deploy four multitool PODs, two in
each zone. If your cluster have more than two zones, scale the deployment such
that there are two PODs in each zone.


```sh
kubectl apply -f deploy/multitool-readiness-probe.yaml
kubectl scale --replicas 4 deploy multitool
```

Initially, none of the PODs will be ready which we can see if we list the PODs
(note the `READY` column):

```
NAME                        READY   STATUS    RESTARTS   AGE     IP              NODE
multitool-5cfbd5449-g7phn   1/2     Running   0          111s    10.244.36.133   node-1
multitool-5cfbd5449-q5gwt   1/2     Running   0          112s    10.244.36.134   node-1
multitool-5cfbd5449-2pb8r   1/2     Running   0          111s    10.244.61.202   node-2
multitool-5cfbd5449-w6x7w   1/2     Running   0          2m12s   10.244.61.201   node-2
```

We will use one of the PODs on `node-1` to observe routing. Open a shell inside
a POD on `node-1`:

```sh
kubectl exec -it <POD on node-1> -- bash
```

We can let Kubernetes know that this POD is ready by creating a file as follows
since the readiness probe watches for availability of this file:

```sh
touch /tmp/ready
```

Now, list the PODs and see that this one POD have `2/2` in the `READY` column
(two containers of two ready).

Next, inside the POD, run the following to query the multitool service. This
will return names of the PODs serving the request.

```sh
for ii in {1..20}; do curl multitool; done
```

Initially we will only see responses from the POD which we manually marked as
ready. Run the following command to mark another POD ready. This time we mark a
POD on `node-2`

```sh
kubectl exec -it <POD on node-2> -- touch /tmp/ready
```

If we re-run the query for-loop, we see responses from both the ready PODs.

We can inspect the global Istio mesh configuration for the locality settings as follows:

> Note: This only works if your Istio mesh is deployed with the Istio operator. Also, your IstioOperator resource might be named differently or you may not be authorized to perform the following operation. If this is the case, just skip this step.

```sh
kubectl -n istio-system get istiooperator istiocontrolplane -o json | jq .spec.meshConfig.localityLbSetting
```

which will show, that locality load balancing is enabled:

```
{
  "enabled": true
}
```

The reason is that while Istio use Kubernetes readiness status similar to
Kubernetes service/endpoints, Istio also monitors status on HTTP
level. E.g. Istio can decide 'readiness' based on the ratio of HTTP
error-codes. This is a significantly more advanced health-check than Kubernetes
readiness checks, and Istio 'health checks' must be configured for Istio to
perform locality-based routing.

Next, configure a traffic policy with 'outlier' definitions (health checks) for
the `multitool` service:

```sh
kubectl apply -f deploy/multitool-dest-rule.yaml
```

and re-run the query. This time we should only observe responses from the POD on
`node-1` because Istio only routes to PODs in the same region and zone:

```sh
for ii in {1..20}; do curl multitool; done
```

We can also mark the second POD on `host-1` as ready, after which we will
observe load balancing between the two PODs on `node-1`:

```sh
kubectl exec -it <Other POD on node-1> -- touch /tmp/ready
```

Istio will fail-over to other localities if there are no available PODs in the
local locality. We can demonstrate this, by marking both PODs on `node-1` as not
ready:

```sh
kubectl exec -it <First POD on node-1> -- rm /tmp/ready
kubectl exec -it <Other POD on node-1> -- rm /tmp/ready
```

If we re-run the queries, we will see, that they are being served from the POD on `node-2`.

Before continuing the exercise, mark the two PODs as ready again:

```sh
kubectl exec -it <First POD on node-1> -- touch /tmp/ready
kubectl exec -it <Other POD on node-1> -- touch /tmp/ready
```

Is full locality-local routing always desirable?

If we only route across localities on case of failures, we do not really know if
it will work, i.e. a mis-configuration could mean that cross-locality routing do
not work or it may incur a high latency. Therefore, even during normal
operations, we might want to route a small percentage of traffic across locality.

Re-configure the traffic policy for the `multitool` to keep 90% of the traffic
locality-local and route the remaining 10% of the traffic to other locality.

> Note that the configuration in `multitool-dest-rule-distribute.yaml` use specific topology key names, i.e. you might need to tailor it to your cluster.

```sh
kubectl apply -f deploy/multitool-dest-rule-distribute.yaml
```

Re-run the queries and see about 10% of the traffic reaching the POD on `node-2`:

```sh
for ii in {1..20}; do curl multitool; done
```

# Cleanup

```sh
kubectl delete -f deploy/multitool-readiness-probe.yaml
kubectl delete -f deploy/multitool-dest-rule-distribute.yaml
```
