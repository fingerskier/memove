#!/usr/bin/env bash
# Regenerates every app icon, favicon and in-app logo from asset/logo.jpg.
# Requires ImageMagick 7 (`magick`). Run from anywhere: tool/gen_icons.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/asset/logo.jpg"
app="$root/flutter"
res="$app/android/app/src/main/res"
ios="$app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
web="$app/web"

# Background gradient of the logo, bottom-left mint to top-right lavender.
# Keep in sync with android/.../drawable/ic_launcher_background.xml.
bg_start='#DFF8F2'
bg_end='#EFEBF9'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

n=1408  # source is 1408x1408

# rounded.png: the logo with its white corners made transparent.
magick -size ${n}x${n} xc:black -fill white \
  -draw "roundrectangle 0,0 $((n - 1)),$((n - 1)) 258,258" "$tmp/mask.png"
magick "$src" "$tmp/mask.png" -alpha off -compose CopyOpacity -composite \
  "$tmp/rounded.png"

# gradient.png: full-bleed background matching the logo's own.
magick -size ${n}x${n} -define gradient:direction=NorthEast \
  gradient:"$bg_start"-"$bg_end" "$tmp/gradient.png"

# square.png: full-bleed logo (corners filled), for platforms that mask.
magick "$tmp/gradient.png" "$tmp/rounded.png" -compose Over -composite \
  -alpha off "$tmp/square.png"

# foreground.png: just the coloured marks on transparency, keyed on chroma
# (the background is near grey, the marks are saturated).
magick "$src" \( +clone -colorspace HCL -channel G -separate +channel \
  -level 20%,45% \) -alpha off -compose CopyOpacity -composite \
  "$tmp/foreground.png"

resize() { # in out size
  magick "$1" -filter Lanczos -resize "$3x$3" -strip "$2"
}

# Android: legacy icon plus adaptive foreground (108dp canvas, logo at 72dp).
for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  dens="${d%%:*}" size="${d##*:}"
  resize "$tmp/rounded.png" "$res/mipmap-$dens/ic_launcher.png" "$size"
  canvas=$((size * 108 / 48)) logo=$((size * 72 / 48))
  magick "$tmp/foreground.png" -filter Lanczos -resize "${logo}x${logo}" \
    -background none -gravity center -extent "${canvas}x${canvas}" -strip \
    "$res/mipmap-$dens/ic_launcher_foreground.png"
done

# iOS: opaque squares, the system applies its own mask.
for f in "$ios"/Icon-App-*.png; do
  base="$(basename "$f" .png)"           # Icon-App-83.5x83.5@2x
  pt="${base#Icon-App-}"; pt="${pt%%x*}" # 83.5
  scale="${base##*@}"; scale="${scale%x}"
  size="$(awk "BEGIN { printf \"%d\", $pt * $scale }")"
  resize "$tmp/square.png" "$f" "$size"
done

# Web: favicon, regular and maskable icons (maskable keeps marks in the
# central 80% safe zone), apple-touch-icon.
resize "$tmp/rounded.png" "$web/favicon.png" 32
for s in 192 512; do
  resize "$tmp/rounded.png" "$web/icons/Icon-$s.png" "$s"
  magick "$tmp/gradient.png" \( "$tmp/foreground.png" -resize 88% \) \
    -gravity center -compose Over -composite -alpha off \
    -filter Lanczos -resize "${s}x${s}" -strip "$web/icons/Icon-maskable-$s.png"
done
resize "$tmp/square.png" "$web/icons/apple-touch-icon.png" 180

# In-app logo.
mkdir -p "$app/assets"
resize "$tmp/rounded.png" "$app/assets/logo.png" 512
