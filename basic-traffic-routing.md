[//]: # (Copyright, Eficode )
[//]: # (Origin: https://github.com/eficode-academy/istio-katas)
[//]: # (Tags: #sentences #kiali)

# Routing Traffic with Istio

## Learning goal

- Using Virtual Services
- Using Destination Rules

## Introduction

This exercise introduces you to the basics of traffic routing with Istio. 
We are going to deploy all the services for our sentences application 
and a new version of the **name** service. This will demonstrate normal 
kubernetes load balancing bewtween services. 

Then we are going to use two Istio custom resource definitions(CRD's) which are
the building blocks of Istio's traffic routing functionality to route traffic to 
the desired workloads.

The VirtualService and the DestinationRule.

### VirtualService

A VirtualService defines a set of traffic routing rules to apply when a host 
is addressed. Each routing rule defines matching criteria for traffic of a 
specific protocol. If the traffic is matched, then it is sent to a named 
destination service (or subset/version of it) defined in the registry.

<details>
    <summary> More Info </summary>

List some of the most important route types, like HTTPRoute, TLSRoute, TCPRoute, etc.

</details>

### DestinationRule

You can think of virtual services as how you route your traffic to a given 
destination, and then you use destination rules to configure **what** happens 
to traffic for that destination.

The most common use of `DestinationRule` is to specify named service **subsets**.

For example, grouping all of a services instances versions. You can then use these 
**subset** in a virtual service to control to different instances.

<details>
    <summary> Example </summary>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-service
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-service-route
spec:
  hosts:
  - my-service
  http:
  - route:
    - destination:
        host: my-service
        subset: v1
    - destination:
        host: my-service
        subset: v2
    - destination:
        host: my-service
        subset: v3
```

</details>

> :bulb: Destination rules are applied **after** virtual service routing rules are evaluated, so they apply 
> to the traffic’s “real” destination.


## Exercise 1

### Overview

- Deploy version 1 of sentences, age and name services. 

- Deploy version 2 of name service.

- Run the script `scripts/loop-query.sh` to produce traffic and observe the output.

- Observe traffic flow in Kiali.

- Route **all** traffic to version 1 of **name** service.

> :bulb: A virtual service lets you configure how requests are routed 
> to a **service** within an Istio service mesh.


### Step by Step
<details>
    <summary> More Details </summary>

**Deploy version 1 of services**

```console
kubectl apply -f deploy/v1
```

**Deploy version 2 of name service**

```console
kubectl apply -f deploy/v2
```

**Run loop-query.sh**

```console
./scripts/loop-query.sh
```

> 

**Observe traffic flow in Kiali**
![50/50 split of traffic](images/kiali-blue-green-anno.png)

> :bulb: 

## Exercise 2

- 

- 

- 
 

### Step by Step
<details>
    <summary> More Details </summary>

**Bold from bullets**

```console
a command
```

**Bold from bullets**

```console
a command
```
</details>

Some summary text!

# Cleanup

```console
kubectl delete -f deploy/v1
```
