#!/bin/bash
filename=$(rofi -dmenu -p "Enter screenshot name:")
if [ -n "$filename" ]; then
  maim -s "$HOME/Pictures/Screenshots/$filename.png"
fi
