#!/usr/bin/env python

import datetime
import json
from authlib.jose import jwt, jwk, JsonWebKey


with open('jwt-key.pub', 'rb') as f:
    key_data = f.read()
obj = jwk.dumps(key_data, kty='RSA')
jwks = {'keys': [obj]}
with open('jwks.json', 'w') as f:
    f.write(json.dumps(jwks))


header = {'alg': 'RS256'}

with open('jwt-key', 'rb') as f:
    key_data = f.read()
key = JsonWebKey.import_key(key_data, {'kty': 'RSA'})

payload = {'sub': 'user1', 'groups': ['user'],
           'iss': 'https://github.com/MichaelVL/istio-katas', 'aud': '*',
           'iat': datetime.datetime.utcnow(),
           'exp': datetime.datetime(year=2030, month=1, day=1)}
s = jwt.encode(header, payload, key)
with open('user1.jwt', 'w') as f:
    f.write(s.decode("ascii"))

payload = {'sub': 'user2', 'groups': ['user'],
           'iss': 'https://github.com/MichaelVL/istio-xxxxx', 'aud': '*',
           'iat': datetime.datetime.utcnow(),
           'exp': datetime.datetime(year=2030, month=1, day=1)}
s = jwt.encode(header, payload, key)
print('<{}>'.format(s))
print('[{}]'.format(s.decode("ascii")))
with open('user2.jwt', 'w') as f:
    f.write(s.decode("utf-8"))

payload = {'sub': 'admin1', 'groups': ['user', 'admin'],
           'iss': 'https://github.com/MichaelVL/istio-katas', 'aud': '*',
           'iat': datetime.datetime.utcnow(),
           'exp': datetime.datetime(year=2030, month=1, day=1)}
s = jwt.encode(header, payload, key)
with open('admin1.jwt', 'w') as f:
    f.write(s.decode("ascii"))
