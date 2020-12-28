# Istio Katas

This repository contain exercises for the Istio service mesh. Exercises assume
access to a Kubernetes cluster with Istio, Kiali and Jaeger tracing.

## Exercises

- [Blue/green Deployments](blue-green-deployment.md)
- [Blue/green Deployments Using Kubernetes Labels](blue-green-deployment-w-labels.md)
- [Canary Deployments](canary-deployment.md)
- [Network Delay Investigations - Simple](request-delays.md)
- [Network Delay Investigations - Larger Application Graph](request-delays-larger-graph.md)
- [Network Delay Investigations with Jaeger](tracing-network-delay.md)
- [WIP: Getting Traffic into the Mesh](getting-traffic-into-mesh.md)
- [WIP: Getting Traffic out of the Mesh](getting-traffic-out-of-mesh.md)
- [WIP: Multiple Teams and Separation of Duties](multi-teams.md)
- Controlling Load Balancing
- [Locality/Topology Aware Load Balancing and Failover](locality-aware-load-balancing.md)
- [WIP:Metrics](metrics.md)

## Deployment Patterns

Exercises will cover the following deployment patterns:

- Blue/green. This pattern have multiple service versions deployed for
  test. Tests are being performed against different versions based on a
  **deliberate choice** of the version to use. I.e. this is typically used for
  tests being performed by testers or test frameworks.

- Canary. This pattern have multiple versions deployed for test and both/all
  versions are in active use. The version to use are determined on each request
  based on **statistics**, e.g. *1% of traffic should go to the test
  version*. Typically its end-users that are being exposed to this.

Typically, blue/green and canary deployments are used in succession. First
blue/green deployments are used to validate a new version in a production
environment such that other production-dependencies can be included in the
tests. When deliberate testing using blue/green deployments have proved the
software to be OK, a larger group of users are exposed to the new version using
canary deployments.

Another deployments pattern is:

- A/B testing. With this type of deployment, a certain percentage of end-users
  are exposed to a test version. This is typically used to test out different
  hypothesis, e.g. "a larger 'Buy' button makes users more liable to buy
  products".

## Test Application

TBD.
