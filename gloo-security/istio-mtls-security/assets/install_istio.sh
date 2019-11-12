curl -L https://github.com/istio/istio/releases/download/1.3.4/istio-1.3.4-linux.tar.gz | tar zxvf -

pushd istio-1.3.4
  export PATH=$PWD/bin:$PATH

  kubectl create namespace istio-system
  helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
  # SDS AUTH
#  helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
#    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml | kubectl apply -f -
  # AUTH
  helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo-auth.yaml | kubectl apply -f -
  source $HOME/util.sh
  wait_until_ready "Istio" "istio-system" "12"

  kubectl label namespace default istio-injection=enabled
  kubectl apply -n default -f samples/bookinfo/platform/kube/bookinfo.yaml
  wait_until_ready "BookInfo" "default" "6"

popd
