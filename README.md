<!--
SPDX-FileCopyrightText: The PerleOS Project
SPDX-License-Identifier: Apache-2.0
-->

# vendor/perleos

PerleOS product configuration on top of `vendor/lineage`. Device products inherit it after the LineageOS common makefile:

```make
$(call inherit-product, vendor/lineage/config/common_full_tablet_wifionly.mk)
$(call inherit-product, vendor/perleos/config/common.mk)
```

`config/common.mk` adds microG and F-Droid (`vendor/microg`) and sets `ro.perleos.version` (`<major>.<minor>-<UTC build date>`) in the `product` build properties.
