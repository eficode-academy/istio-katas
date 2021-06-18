[//]: # (Copyright, Eficode )
[//]: # (Origin: https://github.com/eficode-academy/istio-katas)
[//]: # (Tags: #sentences #kiali)

# Introducing the setup

## Learning goal

- Try out the sentences application
- Add the applications traffic to the istio service mesh
- Familiarize yourself with the Kiali management console

## Introduction

This exercise introduces the sentences application which you will be using during the course.

<details>
    <summary> More Info </summary>

This application implements a simple 'sentences' builder, which can build
sentences from the following simple algorithm:

```
age = random(0,100)
name = random(['Peter','Ray','Egon'])
return name + ' is ' + age + ' years'
```
The application is made up of three services, one which can be queried for the
random age, one which can be queried for a random name and a frontend sentence service, which
calls the two other through HTTP requests and formats the final sentences.

</details>

It also introduces you to the Kiali management console for the Istio service mesh.

<details>
    <summary> More Info </summary>

Kiali provides dashboards and observability by showing you the structure and health of your service mesh.
It provides detailed metrics, Grfana access and integrates with Jaeger for distributed tracing. 

</details>

## Exercise

- Deploy version 1 of the sentences application with kubectl. It is located under the `deploy/v1` directory.

- Run the `loop-query.sh` script located in the `scripts` directory.

- Observe the number of pods running and the output from the `loop-query.sh` script.

### Step by Step
<details>
    <summary> More Details </summary>

Open a terminal in the root of the git repository (istio-katas) and use `kubectl apply -f deploy/v1` to deploy the stack:

Deploy version 1 (`v1`).

```console
kubectl apply -f deploy/v1
```

Observe the number of services and pods running.

```console
kubectl get pod,svc
```

You should see something like:

```console
NAME                             READY   STATUS    RESTARTS   AGE
pod/age-7976688957-mbvzz         1/1     Running   0          2s
pod/name-v1-587b56cdf4-rwcwt     1/1     Running   0          2s
pod/sentences-6dffccb8c6-7fd57   1/1     Running   0          2s

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/age         ClusterIP   172.20.123.133   <none>        5000/TCP         2s
service/name        ClusterIP   172.20.108.51    <none>        5000/TCP         2s
service/name-v1     ClusterIP   172.20.226.141   <none>        5000/TCP         2s
service/sentences   NodePort    172.20.168.218   <none>        5000:30326/TCP   2s
```

In another shell, run the following to continuously query the sentence service and observe the output:

```console
./scripts/loop-query.sh
```

</details>

- Open Kiali, filter by your namespace, and find the sentences application as shown below.

![Sentences with no sidecars](images/kiali-no-sidecars.png)

The red icons beside the workloads mean we have no istio sidecars deployed.
Browse the different tabs to see that there is no traffic nor metrics being captured. 
As there are no sidecars the traffic is not part of the istio service mesh.

- Pull the sentences version 1 deployment down.

- Label your namespace with `istio-injection=enabled` for automtatic sidecar injection.

- Redploy sentences version 1 and run the `loop-query.sh` script.

### Step by Step
<details>
    <summary> More Details </summary>

Pull the version on deployment down.

```console
kubectl delete -f deploy/v1
```

Label **your** namespace (user1, user2, user3, etc) for automatic sidecar injection.

```console
kubectl label namespace <user1> istio-injection=enabled
```

Deploy version 1 (`v1`).

```console
kubectl apply -f deploy/v1
```

Run the `loop-query.sh` script to produce some traffic.

```console
./scripts/loop-query.sh
```

</details>

- Open Kiali, filter by your namespace, and find the sentences application and browse the application.

You should now see traffic and metrics being collected by kiali for the sentnces application.

# Cleanup

```console
kubectl delete -f deploy/v1
```