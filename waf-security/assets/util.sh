function wait_until_ready() {
  name="${1}"
  namespace="${2}"
  target_count="${3}"
  target_pod="${4}"
  while true; do
    if [ -z "${target_pod}" ]; then
      num_running=$(kubectl -n ${namespace} get pods | awk '{print $3}' | grep Running | wc -l | sed "s| ||g")
    else
      num_running=$(kubectl -n ${namespace} get pods | grep ${target_pod} | awk '{print $3}' | grep Running | wc -l | sed "s| ||g")
    fi
echo "num_running $num_running $target_pod " >> ${HOME}/debug
    if [ "${num_running}" == "${target_count}" ]; then
      if [ -z "${target_pod}" ]; then
        pods=$(kubectl -n ${namespace} get pods | grep Running | awk '{print $2}')
      else
        pods=$(kubectl -n ${namespace} get pods | grep ${target_pod} | grep Running | awk '{print $2}')
      fi
      while [ "${num_ready}" != "${target_count}" ]; do
        num_ready=0
        for pod in ${pods}
        do
echo "pod $pod $num_ready $target_pod " >> ${HOME}/debug
          ready=$(echo ${pod} | tr '/' '\n' | uniq -c | wc -l)
          if [ ${ready} == "1" ]; then
            num_ready=$((num_ready+1))
          fi
        done
        if [ -z "${target_pod}" ]; then
          pods=$(kubectl -n ${namespace} get pods | grep Running | awk '{print $2}')
        else
          pods=$(kubectl -n ${namespace} get pods | grep ${target_pod} | grep Running | awk '{print $2}')
        fi
        sleep 5
      done
      echo "All ${num_running} ${name} pods are ready"
      break
    else
        echo "Waiting for all ${name} pods to be running. Current running pods: ${num_running}"
    fi
    sleep 5
  done
}

function install_glooctl() {
  echo "Installing glooctl" > $HOME/status
  mkdir -p $HOME/.gloo/bin
  curl -L https://github.com/solo-io/gloo/releases/download/v0.21.0/glooctl-linux-amd64 --output $HOME/.gloo/bin/glooctl
  chmod +x $HOME/.gloo/bin/glooctl
  export PATH=$HOME/.gloo/bin:$PATH
  glooctl version
  echo "Installed glooctl" > $HOME/status
}

function install_glooe() {
  echo "Installing gloo enterprise" > $HOME/status
  #kubectl apply -f pv.yaml
  #kubectl get pv

  helm repo add glooe http://storage.googleapis.com/gloo-ee-helm

  key=$(cat ../key)
  helm install glooe/gloo-ee --name glooe --namespace gloo-system --set-string license-key=${key} -f value-overrides.yaml
  
  wait_until_ready "Gloo" "gloo-system" "6"
  echo "Installed gloo enterprise" > $HOME/status
}

function install_tiller() {
  echo "Installing tiller" > $HOME/status
  helm init

  wait_until_ready "Tiller" "kube-system" "1" "tiller"
  echo "Installed tiller" > $HOME/status
}
