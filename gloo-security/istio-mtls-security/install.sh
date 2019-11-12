while [ ! -f "$HOME/util.sh" ]; do
  sleep 1
done
source $HOME/util.sh

install_tiller

install_glooctl

install_glooe

~/install_istio.sh

echo "done" > $HOME/status
