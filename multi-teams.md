# Multiple Teams and Separation of Duties

This exercise require an Istio deployment with delegation support. This is not enabled by default in Istio versions prior to 1.8.0.


```sh
source deploy/teams/namespaces.sh
```

```sh
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt

openssl req -out sentences.example.com.csr -newkey rsa:2048 -nodes -keyout sentences.example.com.key -subj "/CN=sentences.example.com/O=ACMEorg"
openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in sentences.example.com.csr -out sentences.example.com.crt

kubectl -nistio-system create secret tls sentences-tls-secret --cert=sentences.example.com.crt --key=sentences.example.com.key
```

```sh
cat deploy/teams/virtual-services-gateway-teams.yaml | envsubst
cat deploy/teams/sentences.yaml | envsubst
```

```sh
cat deploy/teams/sentences.yaml | envsubst | kubectl apply -f -
cat deploy/teams/virtual-services-gateway-teams.yaml | envsubst | kubectl apply -f -
```

Note: gw ns on root vs


```sh
kubectl get po -A -l app=sentences
```

```
NAMESPACE        NAME                        READY   STATUS    RESTARTS   AGE
sentences-age    age-ff8b96898-q8qcq         2/2     Running   0          10m
sentences-name   name-v1-6644f45d6f-nng4r    2/2     Running   0          10m
sentences        sentences-94b98fc4c-scnq5   2/2     Running   0          10m
```

```sh
kubectl get gw,vs -A
```

```
NAMESPACE      NAME                                    AGE
istio-system   gateway.networking.istio.io/sentences   97m

NAMESPACE        NAME                                                GATEWAYS                     HOSTS                       AGE
istio-system     virtualservice.networking.istio.io/sentences-root   ["istio-system/sentences"]   ["sentences.example.com"]   97m
sentences-age    virtualservice.networking.istio.io/age                                                                       97m
sentences-name   virtualservice.networking.istio.io/name                                                                      97m
sentences        virtualservice.networking.istio.io/sentences                                                                 97m
```


```sh
scripts/loop-query-loadbalancer-ep.sh https
```





API gateway


# Cleanup

```sh
cat deploy/teams/sentences.yaml | envsubst | kubectl delete -f -
cat deploy/teams/virtual-services-gateway-teams.yaml | envsubst | kubectl delete -f -
```
