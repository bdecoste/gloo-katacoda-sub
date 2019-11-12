status=$(cat $HOME/status)
[ "$status" == "done" ] && echo "done"
