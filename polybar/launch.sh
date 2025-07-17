#!/usr/bin/env bash

# terminate already running bar instances
killall -q polybar

# wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

# launch
polybar main &

echo "Polybar launched"

