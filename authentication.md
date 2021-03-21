[//]: # (Copyright, Michael Vittrup Larsen)
[//]: # (Origin: https://github.com/MichaelVL/istio-katas)
[//]: # (Tags: #authentication #oidc #jwt #RequestAuthentication #AuthorizationPolicy)

# Authentication

This exercise will demonstrate how to authenticate access to services,
i.e. ensure that only trusted users and services have access to a given
service. Authentication will be done with OIDC tokens and JWKS key sets - see
[here](jwt/README.md) for a description of the tokens and how they are created.

Istio is not an identity provider, i.e. Istio does not issue tokens. However,
Istio can be configured to authenticate and authorize access based on tokens
issues by an identity provider.

Deploy the sentences application without any authorization enabled:

```console
kubectl apply -f deploy/authz/sentences.yaml
```

and test access:

```console
scripts/nodeport-query.sh
```

We will now use the Istio
[RequestAuthentication](https://istio.io/latest/docs/reference/config/security/request_authentication/)
to specify that only tokens issues by us are allowed. In the following you can
use the [example tokens](jwt/README.md) or your own if you have recreated
them. OIDC tokens are signed by the token issuers private key and can be
validated using the issuers public key.

We can see the specification of the issuers public key with this command:

```console
jq . jwt/jwks.json
```

We use the following
[RequestAuthentication](https://istio.io/latest/docs/reference/config/security/request_authentication/)
template and will insert the public key information in the place of the
`KEY_NOM` environment variable. This `RequestAuthentication` specifies, that
tokens issued by `https://github.com/MichaelVL/istio-katas` should be validated
using the public key given in the `jwks` field.

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

Inspect the `RequestAuthentication` with injected key material:

```console
export KEY_NOM=$(jq -r .keys[0].n jwt/jwks.json)
cat deploy/authn/req-authn.yaml | envsubst
```

and deploy it:

```console
cat deploy/authn/req-authn.yaml | envsubst | kubectl apply -f -
```

This will attach the `RequestAuthentication` to the `sentences` front-end service. In many cases it would make more sense to attach the `RequestAuthentication` to the ingress gateway such that invalid tokens are discarded at the edge of the mesh.

<details>
  <summary>Why do you think that we attach the RequestAuthentication to the front-end service here?</summary>
The reason is, that we test access to the `sentences` service using a `NodePort` service, i.e. we do not send traffic through an ingress gateway.
</details>

Next, we test access using an `Authorization` header with an invalid token:

```console
scripts/nodeport-query.sh "Authorization: Bearer X.X.X"
```

Next, try access using a valid token in the `Authorization` header:

```console
export USER1_TOKEN=$(cat jwt/user1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $USER1_TOKEN"
```

With this token we can access the `sentences` service. Now try with another token:

```console
export USER2_TOKEN=$(cat jwt/user2.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $USER2_TOKEN"
```

This token does not allow us to access the `sentences`. If we inspect the token
payload, we also see, that this token use the issuer
`https://github.com/MichaelVL/istio-xxxxx`, which is not an issuer we allowed
with our `RequestAuthentication`, hence why access is not allowed:

```console
cat jwt/user2.jwt | cut -d '.' -f 2  | base64 -d | jq .
```

Next, we try accessing the `sentences` service without an `Authorization` header:

```console
scripts/nodeport-query.sh
```

Surprisingly this requests is allowed access to the `sentences` service!  This
is because, the `RequestAuthentication` only defines how to validate tokens and
not which requests are allowed.

To enable *authorization* such that only tokens from our issuer is allowed, we
can use an [AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/) as follows:

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

If we now try accessing the `sentences` service without an `Authorization`
header we are denied access:

```
RBAC: access denied
```

## Mapping OIDC Issuer and Subject to Istio Principals

Above we allowed access based on the issuer of the token. Istio also allow
access specification using the token subject, i.e. *who* the token was issued
for - which is normally a user/person. We can see the tokens have a `sub` field
with this command:

```console
cat jwt/user1.jwt | cut -d '.' -f 2  | base64 -d | jq .
```

Istio maps workload identities to *principals* using certificates which we saw
in the [Authorization](authorization.mdp) exercise. Similarly, Istio maps
request identities to validated *requestPrincipals* which we can use in
`AuthorizationPolicies`.

Istio maps to `requestPrincipals` using the issuers (`iss`) and subject (`sub`)
fields of the token as follows:

```
istio.requestPrincipals = oidc.iss/oidc.sub
```

Hence our `user1` from the issuer `https://github.com/MichaelVL/istio-katas`
thus become `https://github.com/MichaelVL/istio-katas/user1` when defined as an
Istio `requestPrincipal`.

I.e. with the following `AuthorizationPolicy` we can limit access to the
`sentences` service to `admin1`:

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

Apply the `AuthorizationPolicy` policy

```console
kubectl apply -f deploy/authn/authz-policy-admin1.yaml
```

and verify access for the `admin1` user:

```console
export ADMIN1_TOKEN=$(cat jwt/admin1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $ADMIN1_TOKEN"
```

Also verify that `user1` is no longer allowed access.

## Using OIDC Claims

OIDC have a set of [standard claims](https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims) such as `sub`.

OIDC tokens can be extended with custom claims, and one common extension is a
`groups` claim, i.e. which groups does a given subject belong to. If we inspect
our tokens, we see that our `user1` are part of a `users` group, and our
`admin1` is also part of an `admin` group:

```console
cat jwt/user1.jwt | cut -d '.' -f 2  | base64 -d | jq .
cat jwt/admin1.jwt | cut -d '.' -f 2  | base64 -d | jq .
```

We can add conditions in an `AuthorizationPolicy` to claims in the token,
e.g. to allow access only to subjects from the `admin` groups, we add test to
the AuthorizationPolicy as follows:

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

apply the policy:

```console
kubectl apply -f deploy/authn/authz-policy-claims.yaml
```

and test access:

```console
export ADMIN1_TOKEN=$(cat jwt/admin1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $ADMIN1_TOKEN"
export USER1_TOKEN=$(cat jwt/user1.jwt)
scripts/nodeport-query.sh "Authorization: Bearer $USER1_TOKEN"
```

## Using Dynamic JWKS Key Sets

When we created the RequestAuthentication resource, we embedded the public key
of the token issuer into the resource. This is often not practical. Instead we
can specify an URI in the RequestAuthentication where a JWKS key set can be
obtained. With the example tokens, we can specify an URI to the Github version
of the `jwks.json` file instead of the raw key material:

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

apply the policy:

```console
kubectl apply -f deploy/authn/req-authn-jwks.yaml
```

and test access. Note, that this does not work if you have re-created the tokens
using a new key. In this case you need to update the URI to point to a version
of your new `jwks.json` file containing the new public key.

# Cleanup

```console
kubectl delete requestauthentication jwt-req
kubectl delete authorizationpolicy jwt-req
kubectl delete -f deploy/authz/sentences.yaml
```
