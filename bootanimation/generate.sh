#!/bin/bash
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Generates the PerleOS boot animation with ImageMagick 6 (convert) and Space Grotesk
# from vendor/perleos/fonts. Run from the source tree root:
#   vendor/perleos/bootanimation/generate.sh <output.zip> [preview.gif]
# The logo is the PerleOS wordmark: "Perle" in Space Grotesk Bold, the pearl as the O,
# "S" in Space Grotesk Light, on black.
# part0 plays once (the pearl and its halo light up, then the letters fade in); part1
# loops until boot completes (the halo breathes).

set -euo pipefail
umask 022  # the zip records file modes

out=$(realpath -m "$1")
mkdir -p "$(dirname "$out")"
gif=${2:+$(realpath -m "$2")}
bold=vendor/perleos/fonts/SpaceGrotesk-Bold.ttf
light=vendor/perleos/fonts/SpaceGrotesk-Light.ttf
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

TEXT_COLOR='#F4F1EC'
PEARL_HI='#FFFFFF' NACRE='#E3DAF3' MIST='#A9B7DC'

# Frames are centred on the screen; the rest of the screen stays black.
W=1600 H=900 FPS=30
PT=200                          # font size in px
KERN=$((-PT / 50))              # letter-spacing -0.02em
R=$((PT * 36 / 100))            # pearl diameter 0.72em
MARGIN=$((PT / 50))             # 0.02em on each side of the pearl
SS=4                            # supersampling factor for the pearl

calc() { echo "scale=6; $*" | bc -l; }
advance() {
    convert -debug annotate xc: -font "$1" -pointsize $PT -kerning $KERN -annotate 0 "$2" null: 2>&1 |
        sed -n 's/.*origin: \([0-9]*\),.*/\1/p' | head -1
}

# Wordmark layout: the pearl's bottom sits 0.02em under the baseline, so its top meets
# the cap height (0.70em); the cap height is centred vertically.
wl=$(advance "$bold" Perle)
ws=$(advance "$light" S)
total=$((wl + MARGIN + 2 * R + MARGIN + ws))
x0=$(((W - total) / 2))
base=$((H / 2 + PT * 35 / 100))
PX=$((x0 + wl + MARGIN + R))
PY=$((base + PT / 50 - R))

# PNG24 keeps the black background in RGB; a grey PNG would turn every frame grey.
convert -size ${W}x${H} xc:black PNG24:"$work/bg.png"

# Letters on a transparent layer, positioned on the baseline.
convert -size ${W}x${H} xc:none -fill "$TEXT_COLOR" -kerning $KERN -pointsize $PT \
    -font "$bold" -annotate +$x0+$base Perle \
    -font "$light" -annotate +$((PX + R + MARGIN))+$base S "$work/text.png"

# Pearl, as in the logo: radial gradient centred at (35%, 30%) of its box with an 80%
# radius, stops PEARL_HI 0, NACRE 0.5, MIST 1; a white highlight at (34%, 29%), tilted
# -35 degrees. Drawn SS times larger, then reduced for smooth edges.
c=$(((R + 2) * SS)) d=$(((2 * R + 4) * SS)) r=$((R * SS))
convert \( -size 1x128 gradient:"$MIST"-"$NACRE" \) \( -size 1x128 gradient:"$NACRE"-"$PEARL_HI" \) \
    -append "$work/clut.png"
convert -size ${d}x${d} -define gradient:center=$((c - r * 3 / 10)),$((c - r * 4 / 10)) \
    -define gradient:radii=$((r * 16 / 10)),$((r * 16 / 10)) radial-gradient:white-black \
    "$work/clut.png" -clut \
    \( -size ${d}x${d} xc:black -fill white -draw "circle $c,$c $c,$((c - r))" \) \
    -alpha off -compose copy_opacity -composite \
    \( -size ${d}x${d} xc:none -fill 'rgba(255,255,255,0.85)' \
       -draw "translate $((c - r * 32 / 100)),$((c - r * 42 / 100)) rotate -35 ellipse 0,0 $((r * 28 / 100)),$((r * 16 / 100)) 0,360" \) \
    -compose over -composite -resize $((100 / SS))% "$work/pearl.png"

# Halo around the pearl: a soft NACRE light, drawn once at full strength.
HR=$((R * 2)) G=$((4 * R))
convert -size ${G}x${G} xc:"$NACRE" \
    \( -size ${G}x${G} radial-gradient:white-black -evaluate pow 1.8 -evaluate multiply 0.9 \) \
    -alpha off -compose copy_opacity -composite "$work/halo.png"

# One frame: halo strength g, pearl opacity p, letter opacity n (0-100).
frame() {
    convert "$work/bg.png" \
        \( "$work/halo.png" -channel A -evaluate multiply "$(calc "$2 / 100")" +channel \) \
        -geometry +$((PX - HR))+$((PY - HR)) -compose over -composite \
        \( "$work/pearl.png" -channel A -evaluate multiply "$(calc "$3 / 100")" +channel \) \
        -geometry +$((PX - R - 2))+$((PY - R - 2)) -compose over -composite \
        \( "$work/text.png" -channel A -evaluate multiply "$(calc "$4 / 100")" +channel \) \
        -geometry +0+0 -compose over -composite \
        -depth 8 -strip -define png:exclude-chunks=date,time PNG24:"$1"
}

mkdir -p "$work/anim/part0" "$work/anim/part1"
# part0, 1.5 s: the pearl and its halo fade in over 0.8 s, the letters over 0.6-1.5 s.
for i in $(seq 0 44); do
    p=$((i < 24 ? i * 100 / 24 : 100))
    n=$((i < 18 ? 0 : (i - 18) * 100 / 26)); n=$((n > 100 ? 100 : n))
    frame "$work/anim/part0/$(printf %03d "$i").png" "$p" "$p" "$n"
done
# part1, 2 s loop: the halo breathes between 55 and 100.
for i in $(seq 0 59); do
    g=$(printf '%.0f' "$(calc "77.5 + 22.5 * c($i * 2 * 3.14159265 / 60)")")
    frame "$work/anim/part1/$(printf %03d "$i").png" "$g" 100 100
done

printf '%s %s %s\np 1 0 part0\np 0 0 part1\n' "$W" "$H" "$FPS" > "$work/anim/desc.txt"
# Fixed timestamps, sorted entries and no extra attributes: the same script always gives
# the same zip.
(cd "$work/anim" && rm -f "$out" &&
    find . -exec touch -h -d @1230768000 {} + &&
    find desc.txt part0 part1 -print | LC_ALL=C sort | TZ=UTC zip -q -0 -X "$out" -@)

# Optional preview: part0 then two loops of part1, half size, as an animated GIF.
if [ -n "$gif" ]; then
    mkdir -p "$(dirname "$gif")" "$work/small"
    # Reduce each frame first: the full-size sequence exceeds ImageMagick's cache limits.
    for f in "$work"/anim/part*/*.png; do
        convert "$f" -resize 50% "$work/small/$(basename "$(dirname "$f")")-$(basename "$f")"
    done
    convert -delay 3 -loop 0 "$work"/small/part0-*.png "$work"/small/part1-*.png "$work"/small/part1-*.png \
        -layers Optimize "$gif"
fi
