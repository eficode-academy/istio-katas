#!/usr/bin/env python

import os
import flask
import requests
import prometheus_client
import datetime, time
import logging
import random

random_app = flask.Flask('random')
age_app = flask.Flask('age')
name_app = flask.Flask('name')
sentence_app = flask.Flask('sentence')

authentication_bug_probability = float(os.getenv('SENTENCE_AUTH_BUG_PROBABILITY', 0.0))
min_age = int(os.getenv('SENTENCE_AGE_MIN', 0))
max_age = int(os.getenv('SENTENCE_AGE_MAX', 100))
names = os.getenv('SENTENCE_NAMES', 'Peter,Ray,Egon').split(',')
svc_delay_min = float(os.getenv('SENTENCE_SVC_DELAY_MIN', 0.0))
svc_delay_max = float(os.getenv('SENTENCE_SVC_DELAY_MAX', 0.0))
mode = os.getenv('SENTENCE_MODE', 'age')
age_svc_url = os.getenv('SENTENCE_AGE_SVC_URL', 'http://age:5000')
name_svc_url = os.getenv('SENTENCE_NAME_SVC_URL', 'http://name:5000')
random_svc_url = os.getenv('SENTENCE_RANDOM_SVC_URL', '')

auth_z_bug_value = '12345'

fwd_headers = ['x-request-id',
               'x-b3-traceid',
               'x-b3-spanid',
               'x-b3-parentspanid',
               'x-b3-sampled',
               'x-b3-flags',
               'b3',
               'x-client-trace-id',
               'x-envoy-force-trace',
               # Custom headers
               'x-test',
               'authorization']

class timed():
    def __init__(self, txt):
        self.txt = txt
    def __enter__(self):
        self.start = datetime.datetime.now()
    def __exit__(self, exc_type, exc_value, exc_traceback):
        end = datetime.datetime.now()
        took = (end-self.start).total_seconds()*1000
        logging.warning("Operation '{}' took {:.3f}ms".format(self.txt, took))

def get_random_int(xmin, xmax):
    if random_svc_url:
        with timed('random') as t:
            hdrs = get_fwd_headers()
            logging.warning('Forwarding headers {}'.format(hdrs))
            r = requests.get(random_svc_url, timeout=1, headers=hdrs).text
        return xmin + (int(r) % (xmax-xmin))
    else:
        return random.randint(xmin, xmax)

def get_random_age():
    return str(get_random_int(min_age, max_age))

def get_random_name():
    nidx = get_random_int(0, len(names))
    return names[nidx]
        
def do_random_delay():
    d = svc_delay_min + random.random()*(svc_delay_max-svc_delay_min)
    if d > 0:
        logging.warning('Delay {}s'.format(d))
        time.sleep(d)

def flask_lc_headers():
    return {k.lower(): v for k,v in flask.request.headers.items()}
    
def get_fwd_headers():
    in_hdrs = flask_lc_headers()
    return { h: v for h,v in in_hdrs.items() if h.lower() in fwd_headers}

@random_app.route('/')
def get_random():
    with timed('random') as t:
        do_random_delay()
        in_hdrs = flask_lc_headers()
        if 'authorization' not in in_hdrs or in_hdrs['authorization'] == auth_z_bug_value:
            logging.warning('Simulating bug due to missing/bad authZ header. Got headers: {}'.format(in_hdrs))
            time.sleep(0.7)
        m_requests.labels('random').inc()
        r = random.randint(0, 10000)
        logging.warning("Using random '{}'".format(r))
    return str(r)

@age_app.route('/')
def get_age():
    with timed('age') as t:
        do_random_delay()
        m_requests.labels('age').inc()
        age = get_random_age()
        logging.warning("Using age '{}'".format(age))
    return age

@name_app.route('/')
def get_name():
    with timed('name') as t:
        do_random_delay()
        m_requests.labels('name').inc()
        name = get_random_name()
        logging.warning("Using name '{}'".format(name))
    return name

@sentence_app.route('/')
def get_sentence():
    with timed('sentence') as t:
        do_random_delay()
        hdrs = get_fwd_headers()
        # Simulate authentication and possibly bug
        if float(random.randint(0,100))/100.0 < authentication_bug_probability:
            logging.warning('Simulating authentication bug - adding wrong header')
            hdrs['Authorization'] = auth_z_bug_value
        else:
            hdrs['Authorization'] = 'something-valid'
        logging.warning('Forwarding headers {}'.format(hdrs))
        name = requests.get(name_svc_url, timeout=1, headers=hdrs).text
        age = requests.get(age_svc_url, timeout=1, headers=hdrs).text
        m_requests.labels('sentence').inc()
    return '{} is {} years'.format(name, age)

if __name__ == '__main__':

    host = "0.0.0.0"
    port = 5000
    metrics_port = 8000

    m_requests = prometheus_client.Counter('sentence_requests_total',
                                           'Number of requests', ['type'])
    prometheus_client.start_http_server(metrics_port)

    if mode=='random':
        random_app.run(host=host, port=port)
    elif mode=='age':
        age_app.run(host=host, port=port)
    elif mode=='name':
        name_app.run(host=host, port=port)
    elif mode=='sentence':
        sentence_app.run(host=host, port=port)
