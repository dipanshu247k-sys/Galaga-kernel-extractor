#!/bin/bash

mute(){ exec 3>&1 4>&2; exec > /dev/null 2>&1; }
unmute(){ exec 1>&3 2>&4; exec 3>&- 4>&-; }

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dump_dir> <build_dir>"
    exit 1
fi
mute


DUMP_DIR="$1"
RAW_DST_DIR="$2"
DST_DIR=$(realpath $RAW_DST_DIR)
TMP_DIR="$DST_DIR/tmp"

mkdir -p $DST_DIR/tmp

rm -rf $TMP_DIR/*

for part in dtbo init_boot vendor_boot boot; do
    img="${part}.img"
    unmute
    echo "Processed $img"
    mute
    cp "$DUMP_DIR/$img" image-editor/
    bash image-editor/gradlew -p image-editor unpack
    mkdir -p $TMP_DIR/$part
    mv image-editor/build/unzip_boot/* $TMP_DIR/$part/
    rm image-editor/*.img
done



lz4 -d $TMP_DIR/boot/kernel $DST_DIR/Image
mkdir -p $DST_DIR/{dtb,system,ramdisk,vendor}

cp -r $DUMP_DIR/vendor_dlkm/lib/modules/* $DST_DIR/vendor/
cp -r $DUMP_DIR/system_dlkm/lib/modules/* $DST_DIR/system/
cp $TMP_DIR/vendor_boot/dtb $DST_DIR/dtb/Galaga.dtb


mkdir $TMP_DIR/ramdisk/
cd $TMP_DIR/ramdisk/
cpio -idmv < ../vendor_boot/ramdisk.1

cp -r lib/modules/* $DST_DIR/ramdisk/

unmute

cd ../..
file $DST_DIR/Image
gzip -6 -n -k $DST_DIR/Image
ls -lh $DST_DIR/Image.gz
rm $DST_DIR/Image
rm -rf $DST_DIR/tmp
(cd $DST_DIR && ls -1) | while read dir; do echo "$dir: $(find "$DST_DIR/$dir" -maxdepth 1 -type f | wc -l)"; done
