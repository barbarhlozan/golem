#!/bin/zsh
# Regenerates the app icon and the in-app golems from the hand drawings.
# Run from the repo root after changing Design/golem.png:
#
#   zsh Design/make-icons.sh
#
# Needs ImageMagick (`brew install imagemagick`). The drawing must be dark
# lines on white, with a closed outline: everything outside it becomes
# transparent, and the inside stays white.
set -euo pipefail

src=Design/golem.png
assets=Golem/Resources/Assets.xcassets
tmp=$(mktemp -d)

# Cut out: flood-fill the white around the golem with transparency.
magick $src -alpha off -bordercolor white -border 20 -fuzz 25% \
  -fill none -draw "color 0,0 floodfill" -shave 20x20 $tmp/cut.png

# In-app image: original line weight, cropped close.
magick $tmp/cut.png -trim +repage -strip $assets/Golem.imageset/golem.png

# Icon artwork: thicker lines so they survive at 60 px, golem 680 px tall,
# centred on a 1024 px square (iOS crops the corners).
magick $tmp/cut.png -channel RGB -morphology Erode Disk:1.5 +channel \
  -trim +repage -resize x680 -background none -gravity center \
  -extent 1024x1024 $tmp/icon.png

icons=$assets/AppIcon.appiconset
magick -size 1024x1024 xc:white $tmp/icon.png -composite -alpha off -strip $icons/AppIcon.png
magick $tmp/icon.png -strip $icons/AppIcon-Dark.png
magick $tmp/icon.png -colorspace gray -strip $icons/AppIcon-Tinted.png

rm -rf $tmp
echo "Icons and golem images updated."
