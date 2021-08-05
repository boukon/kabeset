#!/bin/bash
# 
# Usage examples, assuming this script is named `kabeset':
## Providing absolute path: kabeset /run/media/ホモ/Seagate/画像.jpg
## Providing local path:    kabeset subdirectory/image
## Providing remote path:
## 　　kabeset https://www.kabegamikan.com/img/etc/11033.jpg

# If you would like this script to update the `userWallpapers' variable of
## your local (default) or global `plasmarc', then you can set its path here.
# This file is where the normal desktop background menu stores your
## wallpaper history.
# TODO: this is automatically done *sometimes*. experiment and learn when.
plasmarc="/home/$USER/.config/plasmarc"

qdbus-call() {
 # 出典：https://www.kubuntuforums.net/showthread.php/66762-Right-click-
 # 　　　wallpaper-changer?p=387392#post387392
 qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript ' 
  var allDesktops = desktops();
  print (allDesktops);
  for (i = 0; i < allDesktops.length; i++) {
   d = allDesktops[i];
   d.wallpaperPlugin = "org.kde.image";
   d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
   d.writeConfig("Image", "'${1// /\\x20}'")
  }
 '
}

if [ $# -eq 0 ]; then
 hakana_prefix=/tmp/kabeset-壁紙、
 hakana_suffix=ナノ秒
 hakanaikabegami=$hakana_prefix$(date +%N)$hakana_suffix
 cp /dev/stdin $hakanaikabegami || exit 1 &&
 qdbus-call $hakanaikabegami &&
 rm $(
  dir -1 $hakana_prefix[0-9]*$hakana_suffix |
  grep ^$hakana_prefix[0-9][0-9]*$hakana_suffix$ |
  grep -v ^$hakanaikabegami$
 ) # remove the last one (or technically more) that we stored
 exit
fi

# ..a constant reminder to add slideshow support.
[ $# -gt 1 ] && (
  printf "%s\n" "Note: This script only processes one wallpaper."
  printf "%s\n" "      Arguments after '$1' will be ignored."
) > /dev/stderr

# Handle remote file if given, then exit.
if [[ ! -f "$1" && $(expr "$1" : '[^:/]*://.*') ]]
 then qdbus-call "$1"
 exit # Plasma automatically updates wallpaper history in this case.
fi

# Set the wallpaper path variable,
## making sure the 'file://' pseudoprotocol is not already included.
kabegami="$1"
[[ "$kabegami" == file://* ]] && kabegami="${kabegami#file://}"

# Ask the shell if our filepath points to
## an existing file.
[ -f "$kabegami" ] || {
 ( printf "%s\n" "Provided file does not seem to exist." 
   printf "%s\n" "Exiting without setting wallpaper."
 ) > /dev/stderr 
 exit 
}

# Make filepath absolute if it is currently local.
[[ "$kabegami" != "$PWD/"* ]] && kabegami="$(realpath "$kabegami")"

qdbus-call "$kabegami" 

# TODO: What if the filename includes our sed delimiter (|)? The ext4
#       filesystem and others support | in filenames, and `plasmarc' may
#       enforce strict escaping or not support escaping at all.
if [ -f "$plasmarc" ]; then 
 grep "^[[:space:]]*usersWallpapers=.*[,]*$kabegami[,]*" "$plasmarc" >\
 /dev/null || (
  sed -i 's|^\([[:space:]]*usersWallpapers=\)|\1'"$kabegami"',|' "$plasmarc" &&
  grep "^[[:space:]]*usersWallpapers=.*[,]*$kabegami,$"\
   "$plasmarc" > /dev/null && # 異形！（オ＿オ）
  # Remove trailing comma if this is the first wallpaper entry.
  sed -i 's|^\([[:space:]]*usersWallpapers=.*'"$kabegami"'\),$|\1|' "$plasmarc"
 )
fi
