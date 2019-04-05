#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/colors.sh

# Create working directory if it does not exist
if [ ! -d $PROJECT_DIR/working ]; then
	mkdir -p $PROJECT_DIR/working
fi

# clean up
rm -rf $PROJECT_DIR/working/*

# Make sure to get path
if [ -z "$1" ]; then
	echo -e "${bold}${red}Supply ROM path!${nocol}"
	exit 1
fi

# Get files
mkdir -p $PROJECT_DIR/working/rootdir/bin/ $PROJECT_DIR/working/rootdir/etc/
cp -a "$1"/vendor/bin/*.sh $PROJECT_DIR/working/rootdir/bin/
cp -a "$1"/vendor/etc/init/hw/* $PROJECT_DIR/working/rootdir/etc/

# Prepare Android.mk
printf "LOCAL_PATH := \$(call my-dir)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\ninclude \$(CLEAR_VARS)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
# bins
rootdir_bins=`find $PROJECT_DIR/working/rootdir/bin/ -type f -printf '%P\n' | sort`
for file_bins in $rootdir_bins;
do
	printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE       := $file_bins" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_TAGS  := optional eng" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_SRC_FILES    := bin/$file_bins" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_EXECUTABLES)" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
	# rootdir.mk
	printf "$file_bins\n" >> $PROJECT_DIR/working/rootdir_temp.mk
done
# etc
rootdir_etc=`find $PROJECT_DIR/working/rootdir/etc/ -type f -printf '%P\n' | sort`
for file_etc in $rootdir_etc;
do
	printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE       := $file_etc" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_TAGS  := optional eng" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_SRC_FILES    := etc/$file_etc" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_ETC)/init/hw" >> $PROJECT_DIR/working/rootdir/Android.mk
	printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
	# rootdir.mk
	printf "$file_etc\n" >> $PROJECT_DIR/working/rootdir_temp.mk
done

# Get fstab & ueventd & add them to Android.mk
cp -a "$1"/vendor/etc/fstab.qcom $PROJECT_DIR/working/rootdir/etc/fstab.qcom
cp -a "$1"/vendor/ueventd.rc $PROJECT_DIR/working/rootdir/etc/ueventd.qcom.rc
# rootdir.mk
printf "fstab.qcom\nueventd.qcom.rc\n" >> $PROJECT_DIR/working/rootdir_temp.mk
# fstab Android.mk
printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE       := fstab.qcom" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_TAGS  := optional eng" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_SRC_FILES    := etc/fstab.qcom" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_ETC)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
# ueventd Android.mk
printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE       := ueventd.qcom.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_STEM  := ueventd.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_TAGS  := optional eng" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_SRC_FILES    := etc/ueventd.qcom.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk

# Prepare rootdir.mk
awk 'NF{print $0 " \\"}' $PROJECT_DIR/working/rootdir_temp.mk >> $PROJECT_DIR/working/rootdir.mk
sed -i -e 's/^/    /' $PROJECT_DIR/working/rootdir.mk
sed -i '1 i\PRODUCT_PACKAGES += \\' $PROJECT_DIR/working/rootdir.mk
sed -i '1 i\# Ramdisk' $PROJECT_DIR/working/rootdir.mk

# cleanup
rm -rf $PROJECT_DIR/working/rootdir_temp.mk