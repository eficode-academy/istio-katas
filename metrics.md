# Metrics

## A Tour of the Istio Metrics

Note: This exercise assumes an Istio deployment with `enablePrometheusMerge` enabled.

Deploy the sentences application:

```sh
kubectl apply -f deploy/metrics/sentences.yaml
```

Execute `kubectl get pods` and observe that we have one container/POD:

```
NAME                         READY   STATUS    RESTARTS   AGE
age-657d4d9678-q8h7d         1/1     Running   0          3s
name-86969f7468-4qfmp        1/1     Running   0          3s
sentences-779767c659-mlcm9   1/1     Running   0          4s
```

Next, execute `scripts/loop-query.sh` to see the service is running and also to
increment the internal metrics.

Retrieve metrics from the sentences application by querying the POD-level
metrics using the nodeport mapped to the metrics port 8000:

```sh
curl <Any node IP>:<node port for POD port 8000>/metrics | grep sentence_requests_total
```

This should return a value for `sentence_requests_total` which match the number
of requests performed by `scripts/loop-query.sh`.

The deployed version of the sentences application have Istio sidecar injection
disabled. This is done through annotations - investigate the yaml file and
observe the use of the `sidecar.istio.io/inject` annotation:

```
      annotations:
        sidecar.istio.io/inject: 'false'
        prometheus.io/scrape: 'true'
        prometheus.io/port: '8000'
        prometheus.io/path: '/metrics'
```

Also note the Prometheus annotations that informs Prometheus, that this POD can
be scraped for metrics on port `8000` and path `/metrics`.

### Enable Sidecar Injection

Next, we will allow Istio to inject a sidecar. Re-deploy the sentences
application without the annotation that disables sidecar injection:

```sh
cat deploy/metrics/sentences.yaml |grep -v inject | kubectl apply -f -
```

If we run `kubectl get pods` now, we will see that we have two containers/POD.

Next, observe the values of the Prometheus annotations:

```sh
kubectl describe pod -l mode=sentence | head -n 30
```

The result should look like this:

```
Annotations:  prometheus.io/path: /metrics
              prometheus.io/port: 8000
              prometheus.io/scrape: true
              prometheus.istio.io/merge-metrics: false
```

So there is no change in how Prometheus will scrape POD metrics.

What about the Istio metrics from the sidecar?

Istio supports merging Prometheus metrics from the application and the sidecar
into a single scrape endpoint, however this has been disabled with the
annotation `prometheus.istio.io/merge-metrics` (see above).

Re-deploy the sentences application with this annotation removed as well:

```sh
cat deploy/metrics/sentences.yaml |egrep -v 'inject|merge-metrics' | kubectl apply -f -
```

If we now inspect the POD annotations as above, we see:

```
Annotations:  prometheus.io/path: /stats/prometheus
              prometheus.io/port: 15020
              prometheus.io/scrape: true
```

i.e. the metrics scrape endpoint has been moved from the application to the sidecar.

### Fetch Istio Metrics

> The following illustrate how to fetch the merged metrics using the command
> line. If you have Prometheus or e.g. Grafana deployed, you could also use one of
> those to do the queries shown here.

First, list PODs to get their cluster IP:

```sh
kubectl get pods -o wide
```

Next, deploy a test tool (if you prefer, you can use any other tool that have `curl` and `grep`):

```sh
kubectl create deploy multitool --image praqma/network-multitool
kubectl exec -it <multitool container> -- bash
```

Inside the test tool, run `curl` against the metrics scrape endpoint defined by
the POD annotations:

```sh
curl <POD IP>:15020/stats/prometheus | grep requests_total
```

Note, that we both see a `sentence_requests_total` metric and an
`istio_requests_total` metric and they should show the same numeric value. The
Istio metric contain additional labels for e.g. source and destination of
requests. This is the information that Kiali use to dynamically build an
application graph.









## Cleanup

```sh
kubectl delete -f deploy/metrics/sentences.yaml
```
