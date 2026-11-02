#!/bin/zsh
# Cuts the hand-drawn animation frames into the asset catalog.
# Run from the repo root after changing anything in Design/frames:
#
#   zsh Design/make-frames.sh
#
# Needs ImageMagick (`brew install imagemagick`). Each frame is the golem on
# white paper, on the 900 px canvas of Design/golem.png. They're cut out like
# the icon (see make-icons.sh), then all cropped to the same box, not trimmed
# one by one, so the golem doesn't jump between frames.
#
# Only the frames the home screen plays are copied: wake-1 and wake-2 are the
# same drawings as asleep-1 and settling-2, and wake-5 is never shown (the
# restless loop stands in for it, see `GolemReel`).
set -euo pipefail

frames=Design/frames
assets=Golem/Resources/Assets.xcassets
# Union of the frames' outlines on the canvas; widen it if a new drawing
# reaches further.
box=566x603+152+174

used=($frames/asleep-*.png $frames/settling-*.png $frames/restless-*.png
      $frames/wake-3.png $frames/wake-4.png)

for src in $used; do
  name=${${src:t:r}/-/}            # asleep-1 → asleep1
  set=$assets/Golem${(C)name}.imageset
  mkdir -p $set
  magick $src -alpha off -bordercolor white -border 20 -fuzz 25% \
    -fill none -draw "color 0,0 floodfill" -shave 20x20 \
    -crop $box +repage -strip $set/frame.png
  cat > $set/Contents.json <<'JSON'
{
  "images" : [ { "filename" : "frame.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
done

# The ember drawings (ember-<variation>-<frame>) are already white on
# transparent: copied as they are.
for src in $frames/ember-*.png; do
  set=$assets/GolemEmber${${src:t:r}#ember-}.imageset   # ember-2-3 → GolemEmber2-3
  mkdir -p $set
  magick $src -strip $set/frame.png
  cat > $set/Contents.json <<'JSON'
{
  "images" : [ { "filename" : "frame.png", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
done

echo "Golem frames updated."
