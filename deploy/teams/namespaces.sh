kubectl create ns sentences || true
kubectl create ns sentences-age || true
kubectl create ns sentences-name || true

kubectl label ns sentences istio-injection=enabled
kubectl label ns sentences-age istio-injection=enabled
kubectl label ns sentences-name istio-injection=enabled

export SENTENCES_INGRESSGATEWAY_NS=istio-system
export SENTENCES_NS=sentences
export SENTENCES_AGE_NS=sentences-age
export SENTENCES_NAME_NS=sentences-name
