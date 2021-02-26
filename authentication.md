# Authentication

This exercise will demonstrate how to authenticate access services, i.e. ensure
that only trusted users and services have access to a given service with
authentication with OIDC tokens and JWKS key sets - see [here](jwt/README.md)
for a description of the tokens and how they are created.




Deploy the sentences application:

```console
kubectl apply -f deploy/authz/sentences.yaml
```

and test access:

```console
scripts/nodeport-query.sh
```

```console
jq . jwt/jwks.json
```

```console
export KEY_NOM=$(jq -r .keys[0].n jwt/jwks.json)
cat deploy/authn/req-authn.yaml | envsubst
```

```console
cat deploy/authn/req-authn.yaml | envsubst | kubectl apply -f -
```

```console
scripts/nodeport-query.sh "Authorization: Bearer X.X.X"
```

```console
export USER1_TOKEN=$(cat jwt/user1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $USER1_TOKEN"
```

```console
export USER2_TOKEN=$(cat jwt/user2.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $USER2_TOKEN"
```

```yaml
apiVersion: security.istio.io/v1beta1
kind: "RequestAuthentication"
metadata:
  name: jwt-req
spec:
  selector:
    matchLabels:
      app: sentences
      mode: sentence
  jwtRules:
  - issuer: "https://github.com/MichaelVL/istio-katas"
    jwks: |
      { "keys": [{"e":"AQAB","kid":"123","kty":"RSA","n":"$KEY_NOM"}]}

```

```console
cat jwt/user2.jwt | cut -d '.' -f 2  | base64 -d | jq .
```

```console
scripts/nodeport-query.sh
```

Note, that this requests is allowed!  This is because, the
`RequestAuthentication` only defines which JWTs are valid but not that requests
are only allowed if they contain valid JWTs.

To enable *authorization* such that only tokens from our issuer is allowed, we
can use an `AuthorizationPolicy` as follows:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-req
spec:
  selector:
    matchLabels:
      app: sentences
      mode: sentence
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["https://github.com/MichaelVL/istio-katas/*"]

```

```console
kubectl apply -f deploy/authn/authz-policy.yaml
```

```
RBAC: access denied
```

## Mapping OIDC Issuer and Subject to Istio Principals

```
istio.requestPrincipals = oidc.iss/oidc.sub
```

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-req
spec:
  selector:
    matchLabels:
      app: sentences
      mode: sentence
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["https://github.com/MichaelVL/istio-katas/admin1"]

```

```console
kubectl apply -f deploy/authn/authz-policy-admin1.yaml
```

```console
export ADMIN1_TOKEN=$(cat jwt/admin1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $ADMIN1_TOKEN"
```

## Using OIDC Claims

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-req
spec:
  selector:
    matchLabels:
      app: sentences
      mode: sentence
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["https://github.com/MichaelVL/istio-katas/*"]
    when:
    - key: request.auth.claims[groups]
      values: ["admin"]

```

```console
kubectl apply -f deploy/authn/authz-policy-claims.yaml
```

```console
export ADMIN1_TOKEN=$(cat jwt/admin1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $ADMIN1_TOKEN"
```

## Using Dynamic JWKS Key Sets

```yaml
apiVersion: security.istio.io/v1beta1
kind: "RequestAuthentication"
metadata:
  name: jwt-req
spec:
  selector:
    matchLabels:
      app: sentences
      mode: sentence
  jwtRules:
  - issuer: "https://github.com/MichaelVL/istio-katas"
    jwksUri: https://raw.githubusercontent.com/MichaelVL/istio-katas/main/jwt/jwks.json

```

```console
kubectl apply -f deploy/authn/req-authn-jwks.yaml
```

# Cleanup

```console
kubectl delete requestauthentication jwt-req
kubectl delete authorizationpolicy jwt-req
kubectl delete -f deploy/authz/sentences.yaml
```
