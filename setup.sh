#!/bin/bash
git clone --depth=1  https://github.com/cfig/Android_boot_image_editor image-editor
echo "Save Dump in folder dump"
mkdir {build,tmp,dump}
mkdir -p build/{vendor,system,dtb,ramdisk}
