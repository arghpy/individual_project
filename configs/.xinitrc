#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

# invoke global X session script

#### Personal addition ####

## Start dwm at login
#xrandr --output eDP-1 --off --output HDMI-1-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1-1 --off

dwmblocks &

dunst &

compton &

xwallpaper --zoom /home/arghpy/pictures/wallpapers/astronaut.jpeg

#xinput --set-prop 14 335 1

/home/arghpy/.local/bin/touchpad_tap

exec /home/arghpy/.local/bin/start_dwm
