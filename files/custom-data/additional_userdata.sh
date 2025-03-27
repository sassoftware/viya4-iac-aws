#!/bin/bash

# Copyright 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

##
#
# For AWS this is a script 'snippet' that is injected into another script
# which performs tasks that are AWS specific.
#
# Link: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/templates/userdata.sh.tpl
#
##

# Install needed packages
yum -y install nvme-cli mdadm

# Setup ENV's for ease of use
SSD_NVME_DEVICE_LIST=($(nvme list | grep "Amazon EC2 NVMe Instance Storage" | cut -d " " -f 1 || true))
SSD_NVME_DEVICE_COUNT=${#SSD_NVME_DEVICE_LIST[@]}
RAID_DEVICE=${RAID_DEVICE:-/dev/md0}
RAID_CHUNK_SIZE=${RAID_CHUNK_SIZE:-512}  # Kilo Bytes
FILESYSTEM_BLOCK_SIZE=${FILESYSTEM_BLOCK_SIZE:-4096}  # Bytes
STRIDE=$(expr $RAID_CHUNK_SIZE \* 1024 / $FILESYSTEM_BLOCK_SIZE || true)
STRIPE_WIDTH=$(expr $SSD_NVME_DEVICE_COUNT \* $STRIDE || true)

# Checking if provisioning already happened
if [[ "$(ls -A /pv-disks)" ]]
then
  echo 'Volumes already present in "/pv-disks"'
  echo -e "\n$(ls -Al /pv-disks | tail -n +2)\n"
  echo "I assume that provisioning already happened, doing nothing!"
  exit 0
fi

# Perform provisioning based on nvme device count
case $SSD_NVME_DEVICE_COUNT in
"0")
  echo 'No devices found of type "Amazon EC2 NVMe Instance Storage"'
  echo "Maybe your node selectors are not set correct"
  exit 1
  ;;
"1")
  mkfs.ext4 -m 0 -b $FILESYSTEM_BLOCK_SIZE $SSD_NVME_DEVICE_LIST
  DEVICE=$SSD_NVME_DEVICE_LIST
  ;;
*)
  mdadm --create --verbose $RAID_DEVICE --level=0 -c ${RAID_CHUNK_SIZE} \
    --raid-devices=${#SSD_NVME_DEVICE_LIST[@]} ${SSD_NVME_DEVICE_LIST[*]}
  while [ -n "$(mdadm --detail $RAID_DEVICE | grep -ioE 'State :.*resyncing')" ]; do
    echo "Raid is resyncing.."
    sleep 1
  done
  echo "Raid0 device $RAID_DEVICE has been created with disks ${SSD_NVME_DEVICE_LIST[*]}"
  mkfs.ext4 -m 0 -b $FILESYSTEM_BLOCK_SIZE -E stride=$STRIDE,stripe-width=$STRIPE_WIDTH $RAID_DEVICE
  DEVICE=$RAID_DEVICE
  ;;
esac

UUID=$(blkid -s UUID -o value $DEVICE)
mkdir -p /pv-disks/$UUID
echo "UUID=$UUID /pv-disks/$UUID ext4 defaults,noatime,discard,nobarrier 1 2" >> /etc/fstab
mount -a
echo "Device $DEVICE has been mounted to /pv-disks/$UUID"

mkdir -p /nvme
if [ -d "/nvme/disk" ]; then
  if [ -L "/nvme/disk" ]; then
    unlink /nvme/disk
  else
    rm -rf /nvme/disk
  fi
fi
ln -s /pv-disks/$UUID /nvme/disk
echo "/nvme/disk has been symlinked to /pv-disks/$UUID"

mkdir -p /nvme/disk/{cache,saswork}
chmod 777 -R /nvme/disk/
chown -R nobody:nobody /nvme/disk/
