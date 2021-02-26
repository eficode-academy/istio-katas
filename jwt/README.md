# JWT Tokens

This folder contain a tool for creating JWT tokens and JWKS key sets.

The created tokens, their claims, issuer etc. can be found in [create-jwt.py](create-jwt.py).

Before creating tokens, we need to create a key that can be used for signing the
token. Create an password-less RSA key named `jwt-key` with this command:

```console
ssh-keygen -t rsa -b 2048
```

In [Makefile](Makefile) there are targets for building a container-based version
of [create-jwt.py](create-jwt.py). Build the container and run it to create
tokens with the following command:

```console
make build jwt
```

Finally, use the following command to display the JWT payloads:

```console
make show-jwts
```

A JWKS key set file `jwks.json` is also generated. This file contain the public
key used to sign tokens. Use the following command to see content:

```console
jq . jwks.json
```
