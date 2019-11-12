while [ ! -f "$HOME/util.sh" ]; do
  sleep 1
done
source $HOME/util.sh

install_tiller

install_glooctl

install_glooe

kubectl apply -f petstore.yaml

wait_until_ready "Petstore" "default" "1"

export PROXY_URL=$(glooctl proxy url)

sed -i "s|AUTH_APP_URL|${PROXY_URL}|g" gloo-realm.json

$HOME/install_keycloak.sh

echo "done" > $HOME/status
