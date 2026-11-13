#!/bin/bash
# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Generates the PerleOS default wallpaper with ImageMagick 6 (convert): a dark ground,
# Violet #34305E at the top left fading to Night #17162B, with a faint Nacre glow at the
# top right. Run from the source tree root:
#   vendor/perleos/wallpaper/generate.sh
# It writes default_wallpaper.png into every drawable folder where vendor/lineage
# overlays it, so the PerleOS image replaces each of them: at the same sizes, except
# sw600dp and sw720dp at 2560 to match the 2560x1600 panel.

set -euo pipefail

res=vendor/perleos/overlay/frameworks/base/core/res/res
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

wallpaper() {
    local s=$1 dst=$2
    mkdir -p "$(dirname "$dst")"
    # CSS radial-gradient(120% 90% at 20% 10%, #34305E 0%, #17162B 70%).
    convert -size ${s}x${s} -define gradient:center=$((s / 5)),$((s / 10)) \
        -define gradient:radii=$((s * 84 / 100)),$((s * 63 / 100)) \
        radial-gradient:'#34305E'-'#17162B' \
        \( -size ${s}x${s} xc:'#CDBFE8' \
           \( -size ${s}x${s} -define gradient:center=$((s * 84 / 100)),$((s / 5)) \
              -define gradient:radii=$((s * 28 / 100)),$((s * 28 / 100)) \
              radial-gradient:white-black -evaluate multiply 0.22 \) \
           -alpha off -compose copy_opacity -composite \) \
        -compose over -composite -depth 8 -type TrueColor -strip "$dst"
}

wallpaper 960 "$res/drawable-nodpi/default_wallpaper.png"
wallpaper 1080 "$res/drawable-hdpi/default_wallpaper.png"
wallpaper 1440 "$res/drawable-xhdpi/default_wallpaper.png"
wallpaper 1920 "$res/drawable-xxhdpi/default_wallpaper.png"
wallpaper 2560 "$res/drawable-xxxhdpi/default_wallpaper.png"
wallpaper 2560 "$res/drawable-sw600dp-nodpi/default_wallpaper.png"
wallpaper 2560 "$res/drawable-sw720dp-nodpi/default_wallpaper.png"
