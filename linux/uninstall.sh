#!/bin/sh
#https://github.com/eosrei/twemoji-color-font
echo "Blob Color Font font uninstaller for Linux\n"

set -v

# Set XDG_DATA_HOME to default if empty.
if [ -z "$XDG_DATA_HOME" ];then
  XDG_DATA_HOME=$HOME/.local/share
fi
FONTCONFIG=$HOME/.config/fontconfig

rm $XDG_DATA_HOME/fonts/BlobColorFont-SVG.ttf
rm $FONTCONFIG/conf.d/56-blob-color.conf

echo "Clearing font cache"
fc-cache -f

echo "Done!"
