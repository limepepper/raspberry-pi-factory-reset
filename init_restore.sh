#!/bin/sh

reboot_pi () {
  umount /boot
  mount / -o remount,ro
  sync

  echo b > /proc/sysrq-trigger
  sleep 5
  exit 0
}

check_commands () {
  if ! command -v whiptail > /dev/null; then
      echo "whiptail not found"
      sleep 5
      return 1
  fi
  for COMMAND in grep cut sed parted fdisk findmnt partprobe; do
    if ! command -v $COMMAND > /dev/null; then
      FAIL_REASON="$COMMAND not found"
      return 1
    fi
  done
  return 0
}


get_variables () {
  ROOT_PART_DEV=$(findmnt / -o source -n)
  ROOT_PART_NAME=$(echo "$ROOT_PART_DEV" | cut -d "/" -f 3)
  ROOT_DEV_NAME=$(echo /sys/block/*/"${ROOT_PART_NAME}" | cut -d "/" -f 4)
  ROOT_DEV="/dev/${ROOT_DEV_NAME}"
  ROOT_PART_NUM=$(cat "/sys/block/${ROOT_DEV_NAME}/${ROOT_PART_NAME}/partition")

  BOOT_PART_DEV=$(findmnt /boot -o source -n)
  BOOT_PART_NAME=$(echo "$BOOT_PART_DEV" | cut -d "/" -f 3)
  BOOT_DEV_NAME=$(echo /sys/block/*/"${BOOT_PART_NAME}" | cut -d "/" -f 4)
  BOOT_PART_NUM=$(cat "/sys/block/${BOOT_DEV_NAME}/${BOOT_PART_NAME}/partition")

  OLD_DISKID=$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')

  check_noobs

  ROOT_DEV_SIZE=$(cat "/sys/block/${ROOT_DEV_NAME}/size")
  TARGET_END=$((ROOT_DEV_SIZE - 1))

  PARTITION_TABLE=$(parted -m "$ROOT_DEV" unit s print | tr -d 's')

  LAST_PART_NUM=$(echo "$PARTITION_TABLE" | tail -n 1 | cut -d ":" -f 1)

  ROOT_PART_LINE=$(echo "$PARTITION_TABLE" | grep -e "^${ROOT_PART_NUM}:")
  ROOT_PART_START=$(echo "$ROOT_PART_LINE" | cut -d ":" -f 2)
  ROOT_PART_END=$(echo "$ROOT_PART_LINE" | cut -d ":" -f 3)

  if [ "$NOOBS" = "1" ]; then
    EXT_PART_LINE=$(echo "$PARTITION_TABLE" | grep ":::;" | head -n 1)
    EXT_PART_NUM=$(echo "$EXT_PART_LINE" | cut -d ":" -f 1)
    EXT_PART_START=$(echo "$EXT_PART_LINE" | cut -d ":" -f 2)
    EXT_PART_END=$(echo "$EXT_PART_LINE" | cut -d ":" -f 3)
  fi
}

fix_partuuid() {
  DISKID="$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

  sed -i "s/${OLD_DISKID}/${DISKID}/g" /etc/fstab
  sed -i "s/${OLD_DISKID}/${DISKID}/" /boot/cmdline.txt
}





main () {


cat << 'EOF' | tee logger
##      _____          _
##     |  ___|_ _  ___| |_ ___  _ __ _   _
##     | |_ / _` |/ __| __/ _ \| '__| | | |
##     |  _| (_| | (__| || (_) | |  | |_| |
##     |_|  \__,_|\___|\__\___/|_|   \__, |
##                                   |___/
##      ____           _             _
##     |  _ \ ___  ___| |_ ___  _ __(_)_ __   __ _
##     | |_) / _ \/ __| __/ _ \| '__| | '_ \ / _` |
##     |  _ <  __/\__ \ || (_) | |  | | | | | (_| |
##     |_| \_\___||___/\__\___/|_|  |_|_| |_|\__, |
##                                           |___/
EOF

  echo "show blkid"
  blkid
  echo ""

  # dd bs=4M if=/opt/recovery.img of=/dev/mmcblk0p3 conv=fsync status=progress
  unzip -p /opt/recovery.img.zip | \
          dd bs=4M \
          of=/dev/mmcblk0p3 \
          conv=fsync \
          status=progress

  # zipped partition had label copyroot
  e2label /dev/mmcblk0p3 rootfs

  sleep 10

  echo "partprobing"
  partprobe
  echo ""

  echo "sync"
  sync
  echo ""

  printf '\e[?5h'  # Turn on reverse video
  sleep 1
  printf '\e[?5l'  # Turn on normal video

  echo "show filesystem size"
  df -h

  echo "right before sleeping before using blkid"
  sleep 10

  blkid || { echo "unable to run blkid, or error'ed" ; }

  # @TODO should use labels to find these?
  P1_UUID="$(blkid -o value -s UUID /dev/mmcblk0p1)"
  P3_UUID="$(blkid -o value -s UUID /dev/mmcblk0p3)"

  P1_PARTUUID="$(blkid -o value -s PARTUUID /dev/mmcblk0p1)"
  P3_PARTUUID="$(blkid -o value -s PARTUUID /dev/mmcblk0p3)"

  blkid -o value -s UUID /dev/mmcblk0p1
  echo
  blkid
  sleep 10

  [ "${P1_UUID}" ] || { echo "value not populated - ${P1_UUID}"; exit 99 ; }
  [ "${P3_UUID}" ] || { echo "value not populated - ${P3_UUID}"; exit 99 ; }
  [ "${P1_PARTUUID}" ] || { echo "value not populated - ${P1_PARTUUID}"; exit 99 ; }
  [ "${P3_PARTUUID}" ] || { echo "value not populated - ${P3_PARTUUID}"; exit 99 ; }

  mkdir -p /mnt/rootfs
  mount /dev/mmcblk0p3 /mnt/rootfs

  # echo "show blkid for /dev/mmcblk0p3"
  # blkid -o export /dev/mmcblk0p3
  # echo "show blkid for /dev/mmcblk0p3 -p"
  # blkid -p -o export /dev/mmcblk0p3

  if grep 'root=PARTUUID' /boot/cmdline.txt; then
    sed -i -E "s|(root=PARTUUID)=([^[:space:]]+)|root=PARTUUID=$P3_PARTUUID|" \
          /boot/cmdline.txt
  elif grep 'root=UUID' /boot/cmdline.txt; then
    sed -i -E "s|(root=UUID)=([^[:space:]]+)|root=UUID=$P3_UUID|" \
          /boot/cmdline.txt
  else
    echo "unable to find UUID or PARTUUID in cmdline.txt"
    echo "current cmdline.txt is"
    cat /boot/cmdline.txt
    exit 99
  fi

  # remove existing init option
  sed -i "s/init=[^[:space:]]*//g"  /boot/cmdline.txt

  # add resize init script to end of boot option
  echo "$(cat /boot/cmdline.txt) init=/usr/lib/raspi-config/init_resize.sh" > /boot/cmdline.txt_tmp
  cp -f /boot/cmdline.txt_tmp /boot/cmdline.txt

  local fstab_file=/mnt/rootfs/etc/fstab
  local boot_partuuid=$P1_PARTUUID
  local boot_uuid=$P1_UUID
  local root_partuuid=$P3_PARTUUID
  local root_uuid=$P3_UUID

  [ "${boot_partuuid}" ] || { echo "value not populated - ${boot_partuuid}"; exit 99 ; }
  [ "${boot_uuid}" ] || { echo "value not populated - ${boot_uuid}"; exit 99 ; }
  [ "${root_partuuid}" ] || { echo "value not populated - ${root_partuuid}"; exit 99 ; }
  [ "${root_uuid}" ] || { echo "value not populated - ${root_uuid}"; exit 99 ; }

  # if /boot device mount was referenced by a partuuid
  if egrep '^PARTUUID=' "$fstab_file" | grep '/boot' ; then
    echo "/boot was a PARTUUID"
    sed -i -E "s|^PARTUUID=([^[:space:]]+)[[:space:]]+/boot([[:space:]]+)(.*)|PARTUUID=${boot_partuuid}      /boot     \3|" "$fstab_file"
    fixed_boot=1
  fi

  # if /boot device mount was referenced by a uuid
  if egrep '^UUID=' "$fstab_file" | grep '/boot' ; then
    echo "/boot was a UUID"
    sed -i -E "s|^UUID=([^[:space:]]+)[[:space:]]+/boot([[:space:]]+)(.*)|UUID=${boot_uuid}      /boot     \3|" "$fstab_file"
    fixed_boot=1
  fi

  # if / device mount was a partuuid
  if egrep '^PARTUUID=' "$fstab_file" | egrep '[[:space:]]/[[:space:]]' ; then
    echo "/ was a PARTUUID"
    sed -i -E "s|^PARTUUID=([^[:space:]]+)[[:space:]]+/([[:space:]]+)(.*)|PARTUUID=${root_partuuid}      /     \3|" "$fstab_file"
    fixed_root=1
  fi

  # if / device mount was a uuid
  if egrep '^UUID=' "$fstab_file" | egrep '[[:space:]]/[[:space:]]' ; then
    echo "/ was a UUID"
    sed -i -E "s|^UUID=([^[:space:]]+)[[:space:]]+/([[:space:]]+)(.*)|UUID=${root_partuuid}      /     \3|" "$fstab_file"
    fixed_root=1
  fi

  # restore stuff from previous installation

  if [ -f /boot/restore_pi_pass ] ; then
    echo "copying old pi password into new rootfs"
    pi_pass="$(cat /boot/restore_pi_pass)"
    usermod -R /mnt/rootfs -p "$pi_pass" pi
    rm -f /boot/restore_pi_pass
  fi

  if [ -f /boot/restore_root_pass ] ; then
    echo "copying old root password into new rootfs"
    root_pass="$(cat /boot/restore_root_pass)"
    usermod -R /mnt/rootfs -p "$root_pass" root
    rm -f /boot/restore_root_pass
  fi

  if [ -f /boot/wpa_supplicant.conf ] ; then
    # apparently this is done automatically during firstboot if
    # /boot/wpa_supplicant.conf exists, we only need to disable rfkill
    # echo "copying old wifi settings into new partition"
    # cp -f /boot/wpa_supplicant.conf \
    #    /mnt/rootfs/etc/wpa_supplicant/wpa_supplicant.conf
    # rm /boot/wpa_supplicant.conf
    # chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf

    # disable rfkill softtblock for interfaces
    for filename in /mnt/rootfs/var/lib/systemd/rfkill/*:wlan ; do
      echo 0 > $filename
    done
  fi

  # enable the
  touch /boot/ssh

  echo "show filesystem size"
  df -h
  # give time to read the previous message
  sleep 10

  umount /mnt/rootfs

  return 0
}

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t tmpfs tmp /run
mkdir -p /run/systemd

mount /boot
mount / -o remount,rw

sync

echo 1 > /proc/sys/kernel/sysrq

if ! check_commands; then
  reboot_pi
fi

if main; then
  whiptail --infobox "restored filesystem. Rebooting in 5 seconds..." 20 60
  sleep 5
else
  sleep 5
  whiptail --msgbox "Could not restore, rebooting" 20 60
fi

reboot_pi
