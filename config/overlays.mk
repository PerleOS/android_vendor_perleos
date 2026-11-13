# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# PerleOS resource overlays. Device products inherit this before
# vendor/lineage/config/common_*.mk: the first overlay directories take priority, and
# PerleOS replaces resources that vendor/lineage also overlays (default_wallpaper).

PRODUCT_PACKAGE_OVERLAYS += vendor/perleos/overlay
