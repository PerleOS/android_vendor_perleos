# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0

LOCAL_PATH := $(call my-dir)

# LineageOS packages that PerleOS does not ship. Updater: it only queries the LineageOS
# update server, which has no PerleOS builds.
include $(CLEAR_VARS)
LOCAL_MODULE := PerleOSRemovePackages
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_OVERRIDES_PACKAGES := Updater
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := /dev/null
include $(BUILD_PREBUILT)
