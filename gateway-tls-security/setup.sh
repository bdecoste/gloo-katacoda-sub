while [ ! -f "$HOME/status" ]; do
  sleep 2
done

status=$(cat $HOME/status)
while [ "${status}" != "done" ]; do
  echo "Waiting for setup: $status"
  sleep 5
  status=$(cat $HOME/status)
  if [ -f "$HOME/debug" ]; then
    cat $HOME/debug
  fi
done

export PATH=$HOME/.gloo/bin:$PATH
