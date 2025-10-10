#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd -P)"

commands="7z unsquashfs mksquashfs mkpasswd"
for command in $commands; do
    command -v "$command" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Command $command not found"
        exit 1
    fi
done

BOARD_SHORT_NAME=NEBULA
DOWNLOAD_PAGE=download-creality-nebula-smart-kit
ROOT_PASSWORD=creality

if [ -z ${CREALITY_VERSION+x} ]; then
  echo "CREALITY_VERSION isn't set"
  exit 1
fi;
if [ -z ${DOWNLOAD_URL+x} ]; then
    echo "DOWNLOAD_URL isn't set"
    exit 1
fi;

# thanks to Neon for showing me how to derive the password
command -v "openssl" > /dev/null
if [ $? -ne 0 ]; then
  FIRMWARE_PASSWORD=$(mkpasswd -m md5 -S cxswfile "${BOARD_SHORT_NAME}C3_7e_bz")  
  ROOT_HASH=$(mkpasswd -m SHA-512 $ROOT_PASSWORD)
else
  FIRMWARE_PASSWORD=$(openssl passwd -1 -salt cxswfile "${BOARD_SHORT_NAME}C3_7e_bz")
  ROOT_HASH=$(openssl passwd -6 $ROOT_PASSWORD)
fi

echo "Root hash: ${ROOT_HASH}"
echo "Firmware password: ${FIRMWARE_PASSWORD}"

version="6.${CREALITY_VERSION}"

function write_ota_info() {
    echo "ota_version=${version}" > /tmp/${version}-simplyprint/ota_info
    echo "ota_board_name=${board_name}" >> /tmp/${version}-simplyprint/ota_info
    echo "ota_compile_time=$(date '+%Y %m.%d %H:%M:%S')" >> /tmp/${version}-simplyprint/ota_info
    echo "ota_site=http://192.168.43.52/ota/board_test" >> /tmp/${version}-simplyprint/ota_info
    sudo cp /tmp/${version}-simplyprint/ota_info /tmp/${version}-simplyprint/squashfs-root/etc/
}

function customise_rootfs() {
    write_ota_info
    sudo cp $CURRENT_DIR/etc/init.d/* /tmp/${version}-simplyprint/squashfs-root/etc/init.d/
    sudo sed -i "s|^\(root:\)[^:]*|\1$ROOT_HASH|"  /tmp/${version}-simplyprint/squashfs-root/etc/shadow
    sudo cp $CURRENT_DIR/root/* /tmp/${version}-simplyprint/squashfs-root/root/
}

function update_rootfs() {
    pushd /tmp/${version}-simplyprint/ > /dev/null
    sudo unsquashfs orig_rootfs.squashfs 
    customise_rootfs
    sudo mksquashfs squashfs-root rootfs.squashfs || exit $?
    sudo rm -rf squashfs-root
    sudo chown $USER rootfs.squashfs 
}

old_image_name=$(basename $DOWNLOAD_URL)
board_name=$(echo "$old_image_name" | grep -o '^[^_]*')
old_directory="${board_name}_ota_img_V${CREALITY_VERSION}"
old_sub_directory="ota_v${CREALITY_VERSION}"
directory="${board_name}_ota_img_V${version}"
sub_directory="ota_v${version}"
image_name="${board_name}_ota_img_V${version}".img

if [ ! -f /tmp/$old_image_name ]; then
    echo "Downloading ${DOWNLOAD_URL} -> /tmp/$old_image_name ..."
    wget "${DOWNLOAD_URL}" -O /tmp/$old_image_name
fi

if [ -d /tmp/$old_directory ]; then
    rm -rf /tmp/$old_directory
fi

7z x /tmp/$old_image_name -p"$FIRMWARE_PASSWORD" -o/tmp

if [ -d /tmp/${version}-simplyprint ]; then
    sudo rm -rf /tmp/${version}-simplyprint
fi
mkdir -p /tmp/${version}-simplyprint/$directory/$sub_directory

cat /tmp/$old_directory/$old_sub_directory/rootfs.squashfs.* > /tmp/${version}-simplyprint/orig_rootfs.squashfs
orig_rootfs_md5=$(md5sum /tmp/${version}-simplyprint/orig_rootfs.squashfs | awk '{print $1}')
orig_rootfs_size=$(stat -c%s /tmp/${version}-simplyprint/orig_rootfs.squashfs)

# do the changes here
update_rootfs || exit $?

rootfs_md5=$(md5sum /tmp/${version}-simplyprint/rootfs.squashfs | awk '{print $1}')
rootfs_size=$(stat -c%s /tmp/${version}-simplyprint/rootfs.squashfs)

echo "current_version=$version" > /tmp/${version}-simplyprint/$directory/ota_config.in
echo "" > /tmp/${version}-simplyprint/$directory/$sub_directory/ota_v${version}.ok

cp /tmp/$old_directory/$old_sub_directory/ota_update.in /tmp/${version}-simplyprint/$directory/$sub_directory/
cp /tmp/$old_directory/$old_sub_directory/ota_md5_xImage* /tmp/${version}-simplyprint/$directory/$sub_directory/
cp /tmp/$old_directory/$old_sub_directory/ota_md5_zero.bin* /tmp/${version}-simplyprint/$directory/$sub_directory/
cp /tmp/$old_directory/$old_sub_directory/zero.bin.* /tmp/${version}-simplyprint/$directory/$sub_directory/
cp /tmp/$old_directory/$old_sub_directory/xImage.* /tmp/${version}-simplyprint/$directory/$sub_directory/

pushd /tmp/${version}-simplyprint/$directory/$sub_directory > /dev/null
split -d -b 1048576 -a 4 /tmp/${version}-simplyprint/rootfs.squashfs rootfs.squashfs.
popd > /dev/null

part_md5=
for i in $(ls /tmp/${version}-simplyprint/$directory/$sub_directory/rootfs.squashfs.*); do
    file=$(basename $i)
    if [ -z "$part_md5" ]; then
        id=$rootfs_md5
    else
        id=$part_md5
    fi
    mv "/tmp/${version}-simplyprint/$directory/$sub_directory/$file" "/tmp/${version}-simplyprint/$directory/$sub_directory/${file}.${id}"
    part_md5=$(md5sum /tmp/${version}-simplyprint/$directory/$sub_directory/${file}.${id} | awk '{print $1}')
    echo "$part_md5" >> "/tmp/${version}-simplyprint/$directory/$sub_directory/ota_md5_rootfs.squashfs.${rootfs_md5}"
done

sed -i "s/ota_version=$CREALITY_VERSION/ota_version=$version/g" /tmp/${version}-simplyprint/$directory/$sub_directory/ota_update.in
sed -i "s/img_md5=$orig_rootfs_md5/img_md5=$rootfs_md5/g" /tmp/${version}-simplyprint/$directory/$sub_directory/ota_update.in
sed -i "s/img_size=$orig_rootfs_size/img_size=$rootfs_size/g" /tmp/${version}-simplyprint/$directory/$sub_directory/ota_update.in

pushd /tmp/${version}-simplyprint/ > /dev/null
7z a ${image_name}.7z -p"$FIRMWARE_PASSWORD" $directory
mv ${image_name}.7z "${CURRENT_DIR}/${image_name}"
popd > /dev/null
