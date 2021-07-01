export SENTENCES_INGRESSGATEWAY_NS=istio-system
export SENTENCES_NS=sentences
export SENTENCES_AGE_NS=sentences-age
export SENTENCES_NAME_NS=sentences-name

kubectl create ns $SENTENCES_NS      || true
kubectl create ns $SENTENCES_AGE_NS  || true
kubectl create ns $SENTENCES_NAME_NS || true

kubectl label ns $SENTENCES_NS     istio-injection=enabled
kubectl label ns $SENTENCES_AGE_NS  istio-injection=enabled
kubectl label ns $SENTENCES_NAME_NS istio-injection=enabled
