[//]: # (Copyright, Eficode )
[//]: # (Origin: https://github.com/eficode-academy/istio-katas)
[//]: # (Tags: #metrics #prometheus-annotations #sidecar-injection)

# A Tour of the Istio Metrics

## Learning goals

- Basic overview of the metrics Istio provides
- Enabling Prometheus scraping of Istio and application metrics

## Introduction

This exercise will demonstrate how to use metrics from Istio together with
Prometheus. We will also see how application metrics and Istio metrics work
together.

> This exercise assumes an Istio deployment with `enablePrometheusMerge`
> enabled.

Istio provides telemetry for all service communication within the mesh.
This telemetry provides **observability** of service behavior such as
overall traffic volume, error rates in traffic and response times.
All without any additional effort needed by the developer of a service.

One of the types of telemetry Istio generates is metrics. This is done
for **all** service traffic in the mesh. Both inbound and outbound.

Istio provides three levels of metrics.

- Proxy-level: Standard metrics about all pass-through traffic along with
detailed statistics about the administrative functions of the proxy itself.

- Service-level: Service oriented metrics for monitoring the service
communication.

- Control-plane: A collection of self monitoring metrics.

See the [documentation](https://istio.io/latest/docs/concepts/observability/#metrics)
for more details.

> :bulb: If you have not completed exercise
> [00-setup-introduction](00-setup-introduction.md) you **need** to label
> your namespace with `istio-injection=enabled`.

## Exercise

First you will deploy the sentences service without sidecars and inspect
the metrics provided by application. Afterwards you will inject sidecars
and inspect the Istio metrics. Then you will enable a single scrape endpoint
for both the Istio and application metrics. Finally you view and query Istio
metrics in Prometheus.

### Overview

A general overview of what you will be doing in the **Step By Step** section.

- Deploy the sentences application services without sidecars

- Inspect available metrics on a sentences service

- Inject Istio sidecar to sentences services

- Merge Istio and application metrics to one scrape endpoint

> Istio supports merging Prometheus metrics from the application and the sidecar
> into a single scrape endpoint, however this has been disabled with the
> annotation `prometheus.istio.io/merge-metrics`

- Browse Istio Metrics in Prometheus

### Step by Step

Expand the **Tasks** section below to do the exercise.

<details>
    <summary> Tasks </summary>

#### Task: Deploy the sentences application services

___


```console
kubectl apply -f 07-istio-metrics-tour/start/
```

Execute `kubectl get pods` and observe that we have one container per POD.

```
NAME                         READY   STATUS    RESTARTS   AGE
age-657d4d9678-q8h7d         1/1     Running   0          3s
name-86969f7468-4qfmp        1/1     Running   0          3s
sentences-779767c659-mlcm9   1/1     Running   0          4s
```

#### Task: Run the script `scripts/loop-query.sh`

___


Execute `scripts/loop-query.sh` to see the application is running. This will also
update both Istio and sentences application metrics.

```console
./scripts/loop-query.sh
```

#### Task: Inspect available metrics on a sentences service POD port `8000/metrics`

___


To retrieve metrics from a POD in the sentences application we can
query the metrics port 8000. To do that, we deploy a test tool:

```console
kubectl apply -f 07-istio-metrics-tour/multitool
```

and when the POD is ready, we run a shell inside the test tool container:

```console
kubectl exec -it `kubectl get po -l app=multitool -o jsonpath='{.items..metadata.name}'` -- bash
```

Next, look-up an IP of one of the sentence application PODs:

```console
kubectl get pods -o wide
```

Run curl towards one of the POD IPs on port `8000` towards the `/metrics` path. Use `grep`
to filter the output for `requests_total`.

```console
curl -s <POD IP>:8000/metrics | grep requests_total
```

This will return something like the following.

```
# HELP sentence_requests_total Number of requests
# TYPE sentence_requests_total counter
sentence_requests_total{type="name"} 584.0
```

This shows that the POD had received `584` requests from the
`loop-query.sh` script when we fetched metrics.

Keep the terminal inside the test tool - we will use it again later.

#### Task: Inject Istio sidecar to sentences services

___


The deployed version of the sentences application have Istio sidecar injection
**disabled**. This is done through annotations.

You can investigate the yaml file `07-istio-metrics-tour/start/sentences.yaml`
and observe the use of the `sidecar.istio.io/inject` annotation:

```yaml
      annotations:
        sidecar.istio.io/inject: 'false'    # Sidecar injection is disabled
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8000'
        prometheus.io/path: '/metrics'
```

Also note the Prometheus annotations that informs Prometheus, that this POD can
be scraped for metrics on port `8000` and path `/metrics` - similar to what we
just did manually.

Re-deploy the sentences application without the annotation that disables
sidecar injection.

```console
cat 07-istio-metrics-tour/start/sentences.yaml |grep -v inject | kubectl apply -f -
cat 07-istio-metrics-tour/start/name.yaml |grep -v inject | kubectl apply -f -
cat 07-istio-metrics-tour/start/age.yaml |grep -v inject | kubectl apply -f -
```

If we run `kubectl get pods` now, we will see that we have two containers per
POD.

> :bulb: It may take a few seconds for the old PODs to terminate.
> Wait for this before you continue.

Next, observe the values of the Prometheus annotations:

```console
kubectl describe pod -l mode=sentence | head -n 30
```

The result should look like this:

```
Annotations:  prometheus.io/path: /metrics
              prometheus.io/port: 8000
              prometheus.io/scrape: true
              prometheus.istio.io/merge-metrics: false
```

So there is no change in how Prometheus will scrape POD metrics. It
will still use port `8000` which is handled by the sentences
application container. Also, if we re-run the curl command from
previously (with the new pod IP,) we will still only see the `sentence_requests_total`
metric.

#### Task: Merge Istio and application metrics to one scrape point

___


What about the Istio metrics from the sidecar?

Istio supports merging Prometheus metrics from the application and the sidecar
into a single scrape endpoint, however this has been disabled with the
annotation `prometheus.istio.io/merge-metrics` which is set to `false`.

Re-deploy the sentences application service with this annotation removed as well.

```console
cat 07-istio-metrics-tour/start/sentences.yaml |egrep -v 'inject|merge-metrics' | kubectl apply -f -
cat 07-istio-metrics-tour/start/name.yaml |egrep -v 'inject|merge-metrics' | kubectl apply -f -
cat 07-istio-metrics-tour/start/age.yaml |egrep -v 'inject|merge-metrics' | kubectl apply -f -
```

> :bulb: It may take a few seconds for the old PODs to terminate.
> Wait for this before you continue.

If we now inspect the POD annotations as above, we see the metrics scrape
endpoint has moved from the application to the sidecar.

```
Annotations:  prometheus.io/path: /stats/prometheus
              prometheus.io/port: 15020
              prometheus.io/scrape: true
```

#### Task: Fetch Istio Metrics

___


Now that we have a single merged scrape endpoint for the application metrics
and the Istio metrics we can fetch them both.

Re-run the `curl` command inside the test-tool as we did previously,
but this time use the update scrape endpoint information:

```console
curl -s <POD IP>:15020/stats/prometheus | grep requests_total
```

The result of which should look somewhat like the following for e.g.
the `name` service.

```
istio_requests_total{response_code="200",
                     source_workload="sentences",
                     source_version="unknown",
                     destination_workload="name",
                     destination_version="unknown"}   265
sentence_requests_total{type="name"}                  265
```

> Note the output above is edited for clarity.

Note, that we both see a `sentence_requests_total` metric and an
`istio_requests_total` metric - the former generated by the sentences
application and the other by the Istio sidecar. They should show the same
numeric value, however, since the Istio metric contains additional labels,
e.g. source and destination of requests there could be differences
with the request count spread out on differently labelled `istio_requests_total`
metrics.

> The labels `source_workload`, `destination_workload`, `source_version` etc. is
> the primary information Kiali use to dynamically build application graphs and
> versioned graphs. See this link for more information on how [Kiali use
> Prometheus metrics](https://kiali.io/documentation/latest/faq/#prom-metrics)

#### Task: Browse Istio Metrics in Prometheus

___


Istio makes the base monitoring data available but you still need something
to analyze and put the data to use.
[Prometheus](https://istio.io/latest/docs/ops/integrations/prometheus/) is
an open source monitoring system and time series database. You can use
Prometheus with Istio to record metrics that track the health of Istio and
of applications within the service mesh.

Browse to prometheus. The instructor should have given you the URL.

Select the **graph** menu item on the top and enter `istio_requests_total` in
**Expression** box and hit execute.

You should see Istio metrics being returned as shown in the below image.

![Prometheus Istio Requests Total](images/prometheus-istio-requests-total.png)

You can select the **graph** tab to see a graphical representation as shown
below.

![Prometheus Istio Requests Total Graph](images/prometheus-istio-total-graph.png)

The above results are for **all** traffic in the mesh, e.g. including traffic
going through the ingress gateway.

If you want narrow the results down to the traffic between the sentences
services you could replace the expression with
`istio_requests_total{app="sentences"}`. This would give results for **all**
the services labelled with `app=sentences` across all namespaces.

If you wanted the results for a specific service, say the `age` service, in a
specific namespace you could change the expression to use `destination_service`
and specify the full name with `<NAMESPACE>.svc.cluster.local`.

For example to get istio requests total for the `age` service in the `student1`
namespace you could specify the expression
`istio_requests_total{destination_service="age.student1.svc.cluster.local"}`

Although not part of our course setup you can also visualize metrics using
[Grafana](https://istio.io/latest/docs/ops/integrations/grafana/) to create
Dashboards.

</details>

## Summary

In this exercise you have inspected some of the metrics Istio provides along
with how to enable for Prometheus.

Important takeaways are:

- Istio metrics begin with the sidecar. **Each** proxy generates metrics for
**all** traffic passing through the sidecar proxy. Both inbound and outbound.

- By **default** Istio enables only a small subset of envoy generated
statistics to avoid overwhelming the metrics backend.

- Istio provides three sets of metrics. Proxy-level metrics, service-level
metrics and control plane metrics.

- Istio has the ability to control scraping **entirely** by prometheus
annotations and this method is enabled by default. When enabled, appropriate
prometheus annotations will be added to all data plane pods.

For an overview of the standard Istio **service-level** metrics see this
[documentation](https://istio.io/latest/docs/reference/config/metrics/).

## Cleanup

```console
kubectl delete -f 07-istio-metrics-tour/start/
kubectl delete -f 07-istio-metrics-tour/multitool
```
