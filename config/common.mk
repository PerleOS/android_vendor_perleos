# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# PerleOS additions on top of vendor/lineage. Device products inherit this
# after vendor/lineage/config/common_*.mk.

$(call inherit-product, vendor/microg/microg.mk)

PERLEOS_VERSION_MAJOR := 0
PERLEOS_VERSION_MINOR := 1
# Same date as LINEAGE_BUILD_DATE (YYYYMMDD or YYYYMMDD_HHMMSS).
PERLEOS_VERSION := $(PERLEOS_VERSION_MAJOR).$(PERLEOS_VERSION_MINOR)-$(firstword $(subst _, ,$(LINEAGE_BUILD_DATE)))

PRODUCT_PRODUCT_PROPERTIES += \
    ro.perleos.version=$(PERLEOS_VERSION)
