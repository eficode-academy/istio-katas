[//]: # (Copyright, Eficode )
[//]: # (Origin: https://github.com/eficode-academy/istio-katas)
[//]: # (Tags: #sentences #kiali)

# Getting traffic out of the mesh

## Learning goals

- How to access external services
- How to route external (Egress) traffic through Istio gateways

## Introduction

This exercise will introduce you to Istio concepts
and ([CRD's](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/))
for configuring traffic **out** of the service mesh. This is commonly
called Egress traffic.

There are two Istio CRD's in addition to a virtual service needed for this.
The [Gateway](https://istio.io/latest/docs/reference/config/networking/gateway/#Gateway)
and the [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/#ServiceEntry)
CRD's.

First you will route traffic **directly** to an external service from an internal
service with a service entry. Then you will route traffic from an internal
service through a common egress gateway.

This exercise builds on the [Getting Traffic Into The mesh](03-ingress-traffic.md) exercises.

> :bulb: If you have not completed exercise
> [00-setup-introduction](00-setup-introduction.md) you **need** to label
> your namespace with `istio-injection=enabled`.

## Exercise: Egress Traffic

In this exercise you will deploy a **new** version of the **sentences**
service. This new version will use a new **API** service which does nothing
more than make a call to an external service ([httpbin](https://httpbin.org/))
asking for a delay of 1 second for responses. You will then define a ServiceEntry
to allow traffic to the external service. After you have successfully reached
httpbin you will route the traffic through a common egress gateway.

### Service Entry

A ServiceEntry allows you to apply Istio traffic management for services
running **outside** of your mesh. Your service might use an external API
as an example. Once you have defined a service entry you can configure
virtual services and destination rules to apply Istio features like
redirecting or forwarding traffic to external destinations, defining
retries, timeouts and fault injection policies.

> :bulb: In our environment we have set the outBoundTrafficPolicy to
> `REGISTRY_ONLY`.

By default, Istio configures Envoy proxies to **passthrough** requests to
unknown services. So, technically service entries are not required. But
without them you can't apply Istio features as the external service will be
a black hole to the service mesh.

There is also the security aspect to consider. While securely controlling
ingress traffic is the **highest** priority, it is good policy to securely
control egress traffic also. Because of this many clusters will have the
`outBoundTrafficPolicy` set to `REGISTRY_ONLY` as is done in our cluster.
This will force you to define your external services with a service entry.

> **Expand the example below for more details.**

<details>
    <summary> Example </summary>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-api
spec:
  hosts:
  - external-api.example.com
  exportTo:
  - "."
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https-port
    protocol: HTTPS
  resolution: DNS
```

The `hosts` field is used to select matching `hosts` in virtual services
and destination rules. The `resolution` field is used to determine how the
proxy will resolve IP addresses of the end points. The `exportTo` field scopes
the service entry to the namespace where it is defined

> :bulb: The `exportTo` field is important for this exercise. **Not**
> scoping the service entry to your namespace will open the external
> service for **all** attendees.

When you create a service entry it is added to Istio's internal service
registry and traffic is allowed out of the mesh to the defined destination.

Istio maintains an internal service registry containing the set of services,
and their corresponding service endpoints, running in a service mesh.
Istio uses the service registry to generate Envoy configuration.

> Istio does not provide service discovery, although most services are
> automatically added to the registry by Pilot adapters that reflect the
> discovered services of the underlying platform (Kubernetes, Consul, plain DNS).
> Additional services can also be registered manually using a ServiceEntry
> configuration.

</details>

### Gateway

Once a service entry is defined the traffic flows **directly** from the
workloads Envoy sidecar to the external service.

But it is a pretty common use cases to have traffic leaving the mesh
routed **via** a common **egress** gateway.

A Gateway **describes** a load balancer operating at the **edge** of the mesh
receiving incoming or outgoing **HTTP/TCP** connections. The specification
describes the ports to be expose, type of protocol, configuration for the
load balancer, etc.

> **Expand the example below for more details.**

<details>
    <summary> Example </summary>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: myapp-egressgateway
spec:
  selector:
    app: istio-egressgateway
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - external-api.example.com
```

The fields are the same as for the gateway defined for Ingress traffic to
the sentences service in a previous exercise. The notable difference being
that the **selectors** are now the labels on the **Egress** POD
`istio-egressgateway`, which is also running a standalone Envoy proxy just like
the ingress gateway.

The gateway defines an **exit point** to be exposed in the `istio-egressgateway`.
That is it. Nothing else. Just like an ingress entry point, it knows nothing
about how traffic is routed to it.

An Istio **Egress** gateway in a Kubernetes cluster consists, at a minimum, of a
Deployment and a Service. Istio egress gateways are based on Envoy and have a
**standalone** Envoy proxy.

Our course environment would show something like:

```
NAME                                       TYPE
istio-egressgateway                        deployment
istio-egressgateway                        service
istio-egressgateway-8679c48588-2p8vw       pod
```

Inspecting the POD would show something like:

```
NAME                                    CONTAINERS
istio-egressgateway-8679c48588-2p8vw    istio-proxy
```

</details>

In order to route the traffic we, of course, use a virtual service. The gateway
just defines the **exit point** and we still need to define the route.

> **Expand the example below for more details.**

<details>
    <summary> Example </summary>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: external-api-route
spec:
  hosts:
  - external-api.example.com
  exportTo:
  - "."
  gateways:
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        port:
          number: 80
      weight: 100
```

- The route uses the reserved keyword `mesh` implying that this rule applies
to the sidecars in the mesh.

- The exportTo field ensures the virtual service is applied only to the present
namespace.

- The **full DNS name** of the `istio-egressgateway` service is defined instead
of the shortname because the gateway is located in the `istio-system` namespace.

> :bulb: Istio will translate a **short name** based one the **namespace** of the
> **rule**, e.g. if the virtual service is in the `default` namespace it will
> translate to `istio-egressgateway.default.svc.cluster.local`. So **full names**
> should be used when using a gateway in another namespace.

</details>

### Overview

A general overview of what you will be doing in the **Step By Step** section.

- Deploy sentences application services along with an **ingress** gateway and virtual service

- Observe the traffic flow with Kiali

- Define a service entry to allow traffic **out** of the mesh

- Apply some Istio traffic management on the external service

- Modify the the virtual service to route traffic through the **common** gateway

> :bulb: The exit point for [httpbin](http://httpbin.org) and needed routes to
> the `istio-egressgateway` have already been created in the `istio-system`
> namespace. The role based access control (RBAC) in our training environment
> does **not** permit attendees to create resources in the `istio-system`
> namespace.

- Observe the traffic flow with Kiali

### Step by Step

Expand the **Tasks** section below to do the exercise.

<details>
    <summary> Tasks </summary>

#### Task: Deploy sentences application along with ingress gateway and virtual service

___


Deploy `v2` of the sentences application services which has a new api service
along with the ingress gateway entry point and virtual service.

```console
for file in 04-egress-traffic/start/*.yaml; do envsubst < $file | kubectl apply -f -; done
```

Make sure everything is in ready state.

```console
kubectl get gateway,se,vs,dr,svc,pods -n $STUDENT_NS
```

You should now see a gateway, two virtual services and a destination rule along
with four services and pods running. It should look something like below.

```
NAME                                    AGE
gateway.networking.istio.io/sentences   91m

NAME                                            GATEWAYS        HOSTS                                       AGE
virtualservice.networking.istio.io/name-route   ["mesh"]        ["name"]                                    91m
virtualservice.networking.istio.io/sentences    ["sentences"]   ["student1.sentences.istio.eficode.academy"]   91m

NAME                                                        HOST   AGE
destinationrule.networking.istio.io/name-destination-rule   name   91m

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/age         ClusterIP   172.20.101.189   <none>        5000/TCP   91m
service/api         ClusterIP   172.20.8.90      <none>        5000/TCP   91m
service/name        ClusterIP   172.20.6.247     <none>        5000/TCP   91m
service/sentences   ClusterIP   172.20.109.183   <none>        5000/TCP   91m

NAME                                READY   STATUS    RESTARTS   AGE
pod/age-v1-7b9f67b7dc-gbftv         2/2     Running   0          91m
pod/api-v1-75f5bd69f8-l7ndk         2/2     Running   0          91m
pod/name-v1-795cf79f69-h4htd        2/2     Running   0          91m
pod/sentences-v2-75c766ff6c-f68bw   2/2     Running   0          91m
```

#### Task: Run the loop query script with the `hosts` entry

___


```console
./scripts/loop-query.sh -g $STUDENT_NS.sentences.$TRAINING_NAME.eficode.academy
```

#### Task: Observe the responses for the external service

___


Export the pod as an environment variable.

```console
export API_POD=$(kubectl get pod -l app=sentences,mode=api -o jsonpath={.items..metadata.name})
```

Now tail the logs.

```console
kubectl logs "$API_POD" --tail=20 --follow
```

You should see a response of 502(Bad Gateway) because there exists no service entry for
the external service httpbin.

```
INFO:werkzeug:127.0.0.1 - - [10/Aug/2021 12:07:41] "GET / HTTP/1.1" 200 -
WARNING:root:Response was: 502                      <-------------------- Bad Gateway Response
WARNING:root:Operation 'api' took 306.376ms
```

#### Task: Observe the traffic flow with Kiali

___


Go to Graph menu item and select the **Versioned app graph** from the drop
down menu.

![No Service Entry](images/kiali-api-no-se.png)

As there is no service entry all traffic to the external service is blocked
and it is a **black hole** to the service mesh.

#### Task: Define a service entry for httpbin.org

___


Create a service entry called `api-egress-se.yaml` in
`04-egress-traffic/start/`.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  exportTo:
  - "."
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https-port
    protocol: HTTPS
  resolution: DNS
```

Apply the service entry.

```console
kubectl apply -f 04-egress-traffic/start/api-egress-se.yaml
```

#### Task: Observe the responses for the external service

___

Tail the logs.

```console
kubectl logs "$API_POD" --tail=20 --follow
```

Now you should be getting a 200(OK) response from the external service. Also notice, that the external response time was slightly above 1s because we are calling the 'delay service' at `http://httpbin.org/delay/1`:

```
INFO:werkzeug:127.0.0.1 - - [10/Aug/2021 12:21:14] "GET / HTTP/1.1" 200 -
WARNING:root:Response was: 200                <-------------------- OK Response
WARNING:root:Operation 'api' took 1073.259ms
```

#### Task: Observe the traffic flow with Kiali

___


Go to Graph menu item and select the **Versioned app graph** from the drop
down menu.

![Service Entry](images/kiali-api-se.png)

Now Kiali recognizes the external service because of the service entry and it
is no longer a black hole.

#### Task: Create a virtual service with a timeout of 0.5 seconds

___


Basically all we have done so far is to add an entry for httpbin to Istio's
internal service registry. But we can now apply some of the Istio features to
the external service. To demonstrate this you will create a virtual service for
traffic to httpbin with a timeout of `0.5s`.

> The api service asks httpbin.org for a response delay of 1 second and since we are now enforcing a local timeout of 0.5s we are basically configuring the external call to timeout!

Create a file called `api-egress-vs.yaml` in
`04-egress-traffic/start/`.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin.org
  exportTo:
  - "."
  http:
  - timeout: 0.5s
    route:
      - destination:
          host: httpbin.org
        weight: 100
```

Apply the virtual service.

```console
kubectl apply -f 04-egress-traffic/start/api-egress-vs.yaml
```

#### Task: Observe the responses for the external service

___

Tail the logs.

```console
kubectl logs "$API_POD" --tail=20 --follow
```

Now you should be getting a 504(Gateway Timeout) response from the external service.

```
INFO:werkzeug:127.0.0.1 - - [10/Aug/2021 13:29:11] "GET / HTTP/1.1" 200 -
WARNING:root:Response was: 504                <-------------------- 504 Gateway Timeout
WARNING:root:Operation 'api' took 504.809ms
```

Change the timeout to something greater than 1 second and ensure that you get 200(OK) responses.

#### Task: Modify the the virtual service to route traffic through the common gateway

___


**Modify the `api-egress-vs.yaml` from previous step**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - httpbin.org
  exportTo:
  - "."
  gateways:
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        port:
          number: 80
      weight: 100
```

Apply the changes.

```console
kubectl apply -f 04-egress-traffic/start/api-egress-vs.yaml
```

#### Task: Observe the responses for the external service

___

Tail the logs.

```console
kubectl logs "$API_POD" --tail=20 --follow
```

You should be getting a 200(OK) response from the external service and a delay of 1 second:

```
INFO:werkzeug:127.0.0.1 - - [10/Aug/2021 12:21:14] "GET / HTTP/1.1" 200 -
WARNING:root:Response was: 200                <-------------------- OK Response
WARNING:root:Operation 'api' took 1080.768ms
```

#### Task: Observe the traffic flow with Kiali

___


Go to Graph menu item and select the **Versioned app graph** from the drop
down menu. Select the checkboxes as shown in the below image.

You will see traffic to the sentences service entering through the ingress
gateway in the `istio-ingress` namespace. Traffic from the api service is now
leaving through the common egress gateway in the `istio-system` namespace.

> Note depending on the version of Kiali in use the graph may look disconnected
> between the api service and the external service.

![API Egress](images/kiali-api-egress.png)

</details>

# Summary

In this exercise you created a service entry to allow access to an
external service. This is a pretty common use case. A lot of service
meshes will have a `REGISTRY_ONLY` policy defined for security reasons.
So you should be aware of what a service entry does.

Afterwards you created a virtual service to demonstrate Istio traffic
management for traffic to an external service. Finally, you routed the
traffic to the external service through a **common** egress gateway.

The main takeaways are:

- If traffic is **not** flowing through the mesh, e.g through the
envoy sidecars, then you cannot leverage Istio features. Regardless
of whether it is ingress or egress traffic.

- Service entries are needed if the **default** passthrough logic to
external service is disabled.

- Gateways define an exit point for load balancer operating at the edge of
the mesh. You still need to route traffic to the gateway and the external
service.

# Cleanup

```console
kubectl delete -f 04-egress-traffic/start/
```
