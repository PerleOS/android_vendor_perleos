#!/bin/bash
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Generates the PerleOS boot animation with ImageMagick 6 (convert) and the Roboto font
# from external/roboto-fonts. Run from the source tree root:
#   vendor/perleos/bootanimation/generate.sh <output.zip> [preview-dir]
# part0 plays once (the pearl lights up, then the name fades in); part1 loops until boot
# completes (the pearl's glow breathes).

set -euo pipefail

out=$(realpath -m "$1")
mkdir -p "$(dirname "$out")"
preview=${2:-}
font=external/roboto-fonts/RobotoStatic-Regular.ttf
W=1600 H=600 FPS=30
PX=520 PY=300 R=78           # pearl centre and radius
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Pearl body: off-white sphere lit from the upper left, with a faint pink and blue sheen,
# on a canvas 2 px larger than the sphere on each side so its edge is not clipped.
c=$((R + 2)) d=$((2 * R + 4))
convert -size ${d}x${d} -define gradient:center=$((c - R * 3 / 10)),$((c - R * 4 / 10)) \
    -define gradient:radii=$((R * 16 / 10)),$((R * 16 / 10)) radial-gradient:'#fffdfb'-'#6f6863' \
    \( -size ${d}x${d} -define gradient:angle=135 gradient:'#f4d6e0'-'#cfdcf2' \) \
    -compose softlight -composite \
    \( -size ${d}x${d} xc:black -fill white -draw "circle $c,$c $c,2" \) \
    -alpha off -compose copy_opacity -composite "$work/pearl.png"
# Specular highlight.
convert -size ${d}x${d} xc:none -fill 'rgba(255,255,255,0.85)' \
    -draw "ellipse $((c - R * 3 / 10)),$((c - R * 45 / 100)) $((R * 22 / 100)),$((R * 15 / 100)) 0,360" \
    -blur 0x$((R / 12)) "$work/highlight.png"
convert "$work/pearl.png" "$work/highlight.png" -compose over -composite "$work/pearl.png"

# Name, right of the pearl.
convert -background none -fill '#ececec' -font "$font" -pointsize 150 -kerning 4 \
    label:PerleOS "$work/name.png"

# One frame: glow strength g (0-100), pearl opacity p (0-100), name opacity n (0-100).
frame() {
    local f=$1 g=$2 p=$3 n=$4
    convert -size ${W}x${H} xc:black \
        \( -size ${W}x${H} xc:none -fill "rgba(255,244,236,$(echo "scale=3; $g / 100 * 0.55" | bc))" \
           -draw "circle $PX,$PY $PX,$((PY - R - 34))" -blur 0x36 \) -compose screen -composite \
        \( "$work/pearl.png" -channel A -evaluate multiply "$(echo "scale=3; $p / 100" | bc)" +channel \) \
           -geometry +$((PX - c))+$((PY - c)) -compose over -composite \
        \( "$work/name.png" -channel A -evaluate multiply "$(echo "scale=3; $n / 100" | bc)" +channel \) \
           -gravity west -geometry +$((PX + R + 60))+0 -compose over -composite \
        -gravity northwest -depth 8 -type TrueColor "$f"
}
sine() { echo "scale=6; s($1)" | bc -l; }

mkdir -p "$work/anim/part0" "$work/anim/part1"
# part0: 0-0.8 s pearl fades in with its glow, 0.6-1.5 s the name fades in.
for i in $(seq 0 44); do
    p=$(( i < 24 ? i * 100 / 24 : 100 ))
    n=$(( i < 18 ? 0 : (i - 18) * 100 / 26 )); n=$(( n > 100 ? 100 : n ))
    frame "$work/anim/part0/$(printf %03d "$i").png" "$p" "$p" "$n"
done
# part1: 2 s loop, glow between 55 and 100.
for i in $(seq 0 59); do
    s=$(sine "$i * 2 * 3.14159265 / 60")
    g=$(echo "scale=0; (77.5 + 22.5 * $s) / 1" | bc)
    frame "$work/anim/part1/$(printf %03d "$i").png" "$g" 100 100
done

printf '%s %s %s\np 1 0 part0\np 0 0 part1\n' "$W" "$H" "$FPS" > "$work/anim/desc.txt"
(cd "$work/anim" && rm -f "$out" && zip -q -0 -r "$out" desc.txt part0 part1)
if [ -n "$preview" ]; then
    mkdir -p "$preview"
    cp "$work/anim/part0/044.png" "$work/anim/part1/000.png" "$work/anim/part1/015.png" "$preview/" 2>/dev/null || true
fi
