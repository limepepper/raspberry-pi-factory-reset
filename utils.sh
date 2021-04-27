

function check_sources(){
  [ -f ${IMG_ORIG} ] || { echo "Not found source image '${IMG_ORIG}'" && exit;  }
  [ -f ${RECOVERY_SCRIPT_SOURCE} ] || { echo "Not found ${RECOVERY_SCRIPT_SOURCE}" && exit;  }
  echo "check_sources complete"
}

function cleanup()
{
  sudo umount -f -d mnt/restore_boot > /dev/null 2>&1 || true
  sudo umount -f -d mnt/restore_rootfs > /dev/null 2>&1 || true
  sudo umount -f -d mnt/restore_recovery > /dev/null 2>&1 || true

  for imgname in $IMG_RESTORE $IMG_LIVE; do
    # echo $imgname
    while losetup -a | grep "${imgname}" > /dev/null 2>&1; do
      TMPLOOP="$(losetup -a | grep "${imgname}" | head -1| awk '{ print $1 }')"
      TMPLOOP=${TMPLOOP%:}
      echo $TMPLOOP
      sudo losetup --detach ${TMPLOOP}
      echo removed
    done
  done

}

# the main idea here is to be able to recover from a failed build
cleanup_pre(){
  echo "cleaning up pre"
  cleanup
  echo "cleaned up pre"
}

# the main idea of having a cleanup post method distinct from pre
# was that it would be considered a successful build, and therefore
# remove any intermediate images and stuff that would be useful for
# debugging
cleanup_post(){
  echo "cleaning up post"
  cleanup
  echo "cleaned up post"
}

function check_prerequisites()
{
  pr_header "prerequisite checks"

  cmds=(
      uuidgen
      zip
      tune2fs
      losetup
      partprobe
      blkid
      e2label
  )

  for cmd in "${cmds[@]}"; do
    if ! command -v ${cmd} > /dev/null; then
      echo "need command \"${cmd}\" installed... exiting"
      exit 99
    fi
  done
}


# generate new UUIDs for the copy of the original image
function make_uuids(){
  # partuuid seems to get reset by resize.sh, however UUID doesn't seem to work
  set +o pipefail
  PARTUUID=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)
  set -o pipefail

  [ ! -z ${PARTUUID} ] || { echo "PARTUUID is empty '${PARTUUID}'" && exit 99;  }

  pr_ok "PARTUUID generated is ${PARTUUID}"

  # because of cloning the images, need to generate new UUIDs
  UUID_RESTORE=$(uuidgen)
  UUID_ROOTFS=$(uuidgen)
}

# make a copy of the original img file
# mounts the partitions from the new img onto loopback devices
#
function make_looplive_and_mount(){

  pr_header "make a copy of the pristine image for use as the live rootfs"

  [[ -f "${IMG_LIVE}" ]] && \
  {
    pr_warn "live file ${IMG_LIVE} already, exists - overwriting"
    cp -f ${IMG_ORIG} ${IMG_LIVE}
    pr_ok "${IMG_LIVE} already, exists - overwriting"
  } || \
  {
    cp -f ${IMG_ORIG} ${IMG_LIVE}
    pr_ok "${IMG_LIVE} created"
  }

  LOOP_LIVE=$(sudo losetup --show -f -P ${IMG_LIVE})
  echo "LOOP LIVE is ${LOOP_LIVE}"
  sudo partprobe ${LOOP_LIVE}
  echo ""

  # cat /proc/partitions
  sudo losetup -a
  sudo blkid
  echo ""
}

function get_uuid_for_boot(){

  # @TODO this seems to be using the same UUID for live and restore???
  # UUID_BOOT gets used later which writing fstab out
  # set UUID_BOOT from live img boot partition
  UUID_BOOT=$(blkid -o export ${LOOP_LIVE}p1 | egrep '^UUID=' | cut -d'=' -f2)

  # fail if we didn't get the boot UUID
  [  -z "$UUID_BOOT" ] && \
  {
    echo "UUID_BOOT Empty: Yes"
    exit 99
  } || \
  {
    echo "Empty: No"
    pr_warn "UUID_BOOT is ${UUID_BOOT}"
  }

  pr_warn "UUID_BOOT is ${UUID_BOOT}"
  echo ""

}

# the restore img is the file that contains the partitions that will
# ultimately get written out to the sdcard
function make_looprestore_and_mount(){

  pr_header "make img restore and mount it"

  # sizes used here are just a guess at something that will be big enough
  # it would probably make sense to calculate this correctly to save
  # time writing, zipping and flashing out 8GB files
  [[ -f "${IMG_RESTORE}" ]] && \
  {
    pr_warn "restore file ${IMG_RESTORE} already, exists - overwriting"
    dd if=/dev/zero bs=4M count=2048 > ${IMG_RESTORE}
  } || \
  {
    pr_ok "restore file ${IMG_RESTORE} creating"
    dd if=/dev/zero bs=4M count=2048 > ${IMG_RESTORE}
    # touch ${IMG_RESTORE}
  }
  fdisk -l ${IMG_RESTORE}

  [[ -z "${PARTUUID}" ]] && {
      echo "partuuid is empty"
      exit 99
      }

# this could also be dynamically determined, but needs partition 2 to be
# large enough to fit a zipped copy of partiion 3 for restoring
# so these are just hard coded based on trial and error per Pi OS release

  tmpfile=$(mktemp /tmp/reset_sfdisk.XXXXXX)

  case $BASE in

  "2021-01-11-raspios-buster-armhf-lite")
cat << EOF > ${tmpfile}
label: dos
label-id: 0x${PARTUUID}
unit: sectors

${IMG_RESTORE}1 : start=8192,     size=524288,    type=c
${IMG_RESTORE}2 : start=532480,   size=4028768,   type=83
${IMG_RESTORE}3 : start=4561248,  size=3104768,   type=83

EOF
    ;;

  "2021-03-04-raspios-buster-armhf-lite")
cat << EOF > ${tmpfile}
label: dos
label-id: 0x${PARTUUID}
unit: sectors

${IMG_RESTORE}1 : start=8192,     size=524288,    type=c
${IMG_RESTORE}2 : start=532480,   size=4028768,   type=83
${IMG_RESTORE}3 : start=4561248,  size=3112960,   type=83

EOF
    ;;
    *)
cat << EOF > ${tmpfile}
label: dos
label-id: 0x${PARTUUID}
unit: sectors

${IMG_RESTORE}1 : start=8192,     size=524288,    type=c
${IMG_RESTORE}2 : start=532480,   size=4028768,   type=83
${IMG_RESTORE}3 : start=4561248,  size=3104768,   type=83

EOF
      ;;
  esac

  sfdisk ${IMG_RESTORE} < "$tmpfile"

  cat "$tmpfile"
  #rm "$tmpfile"

  fdisk -lu ${IMG_RESTORE}

  LOOP_RESTORE=$(sudo losetup -v  --show -f -P ${IMG_RESTORE})

  pr_header "partprobe the new loopback device - ${LOOP_RESTORE}"
  sudo partprobe ${LOOP_RESTORE}

  pr_header "show the partitions"
  losetup -a

}

function copy_live_to_restore(){

  pr_header "3.4 copy the filesystem partitions to the restore img"

  sudo dd if=${LOOP_LIVE}p1 of=${LOOP_RESTORE}p1 bs=4M
  sudo dd if=${LOOP_LIVE}p2 of=${LOOP_RESTORE}p2 bs=4M
  sudo dd if=${LOOP_LIVE}p2 of=${LOOP_RESTORE}p3 bs=4M

  # make sure the partitions on the loop device are available
  sudo partprobe ${LOOP_RESTORE}

  pr_header "3.6 call tunefs to set label and UUID"

  echo $UUID_RESTORE
  echo $LOOP_RESTORE

  sudo tune2fs ${LOOP_RESTORE}p2 -U ${UUID_RESTORE}
  sudo e2label ${LOOP_RESTORE}p2 recoveryfs

  sudo tune2fs ${LOOP_RESTORE}p3 -U ${UUID_ROOTFS}

  pr_header "3.7 call partprobe"
  sudo partprobe ${LOOP_RESTORE}

  pr_header "3.8 resize the fs on the recovery partition to fit the restore img"
  sudo e2fsck -f ${LOOP_RESTORE}p2
  # this is necessary to make the space for the recovery.zip
  sudo resize2fs ${LOOP_RESTORE}p2

  sudo fdisk -l ${LOOP_RESTORE}

  mkdir -p mnt/restore_boot
  mkdir -p mnt/restore_recovery
  mkdir -p mnt/restore_rootfs

  sudo mount ${LOOP_RESTORE}p1 mnt/restore_boot
  sudo mount ${LOOP_RESTORE}p2 mnt/restore_recovery
  sudo mount ${LOOP_RESTORE}p3 mnt/restore_rootfs

}


function overwrite_cmdline_for_boot(){

  pr_header "4.0 current boot cmdline.txt"
  cat mnt/restore_boot/cmdline.txt

  pr_header "4.1 create the boot from live rootfs cmdline.txt"

sudo tee mnt/restore_boot/cmdline.txt << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID}-03 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait init=/usr/lib/raspi-config/init_resize.sh
EOF

  pr_header "4.3 create alt cmd file for recovery boot"

sudo tee mnt/restore_boot/cmdline.txt_recovery << EOF
console=serial0,115200 console=tty1 root=PARTUUID=XXXYYYXXX rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=${RECOVERY_SCRIPT_TARGET}
EOF

}

# doesn't wait for error message
function fix_resize_script(){

  sudo cp "${RESIZE_SCRIPT_SOURCE}" "mnt/restore_rootfs${RESIZE_SCRIPT_TARGET}"
  sudo chmod +x "mnt/restore_rootfs${RESIZE_SCRIPT_TARGET}"

  sync

}

function enable_rpi_serial_console(){

  pr_header "4.0 current boot config.txt"
  cat mnt/restore_boot/config.txt

  egrep -qx '^enable_uart=' mnt/restore_boot/config.txt &&
  {
    sudo sed -i 's/^enable_uart.*/enable_uart=1/' mnt/restore_boot/config.txt
  } ||
  {
    echo 'enable_uart=1' | sudo tee -a mnt/restore_boot/config.txt
  }

}

function make_restore_script(){
#   ___        _               ___         _      _
#  | _ \___ __| |_ ___ _ _ ___/ __| __ _ _(_)_ __| |_
#  |   / -_|_-<  _/ _ \ '_/ -_)__ \/ _| '_| | '_ \  _|
#  |_|_\___/__/\__\___/_| \___|___/\__|_| |_| .__/\__|
#                                           |_|

  pr_header "4.4 create factory reset script - run this from live"

sudo tee mnt/restore_boot/factory_reset << EOF
#!/bin/bash

echo "factory restore script"

[[ "\$1" == "--reset" ]] && \
{
  echo "resetting"

  if [[ \$(/usr/bin/id -u) -ne 0 ]]; then
    echo "This needs to run as root"
    exit 99
  fi

  sleep 5

  echo "show original cmdline.txt"
  cat /boot/cmdline.txt
  echo ""

  cp -f /etc/fstab /boot/fstab_original

  cp -f /boot/cmdline.txt /boot/cmdline.txt_original
  cp -f /boot/cmdline.txt_recovery /boot/cmdline.txt
  sed -i "s/XXXYYYXXX/\$(blkid -o export  \
        /dev/disk/by-label/recoveryfs | \
         egrep '^PARTUUID=' | cut -d'=' -f2)/g" /boot/cmdline.txt
  echo "show blkid"
  blkid
  echo ""

  echo "show mount | grep mmc"
  mount | grep mmc
  echo ""

  echo "show rootfs fstab"
  cat /etc/fstab
  echo ""

  echo "show recoveryfs fstab"
  mkdir -p /mnt/recoveryfs
  mount /dev/disk/by-label/recoveryfs /mnt/recoveryfs
  cat /mnt/recoveryfs/etc/fstab

  umount -f /mnt/recoveryfs
  echo ""

  echo "show current cmdline.txt"
  cat /boot/cmdline.txt
  echo ""

  # pause before rebooting to check debugs
  echo "rebooting..."
  # read -p "Press [Enter] key to start reboot..."
  reboot
  exit 0
}

EOF

  sudo chmod +x mnt/restore_boot/factory_reset

  pr_header "4.7 copy init_restore.sh to recovery"
  sudo cp "${RECOVERY_SCRIPT_SOURCE}" "mnt/restore_recovery${RECOVERY_SCRIPT_TARGET}"
  sudo chmod +x "mnt/restore_recovery${RECOVERY_SCRIPT_TARGET}"

  pr_header "4.8 current boot cmdline.txt"
  cat mnt/restore_boot/cmdline.txt

  pr_header "4.9 current boot cmdline.txt txt_recovery"
  cat mnt/restore_boot/cmdline.txt_recovery

  pr_header "4.9.1 enable ssh on the image"
  sudo touch mnt/restore_boot/ssh

}


function make_recovery_script(){

  pr_header "current recovery fstab"
  cat mnt/restore_recovery/etc/fstab

  pr_header "indicate this is a recovery shell"

# not sure this is getting used on the console...?
sudo tee mnt/restore_recovery/etc/motd << EOF
##    ____  _____ ____ _____     _______ ______   __
##   |  _ \| ____/ ___/ _ \ \   / / ____|  _ \ \ / /
##   | |_) |  _|| |  | | | \ \ / /|  _| | |_) \ V /
##   |  _ <| |__| |__| |_| |\ V / | |___|  _ < | |
##   |_| \_\_____\____\___/  \_/  |_____|_| \_\|_|
##
EOF

pr_header "map the recovery fstab to the 2nd partition"
sudo tee mnt/restore_recovery/etc/fstab << EOF
proc                    /proc  proc    defaults          0       0
UUID=${UUID_BOOT}       /boot  vfat    defaults          0       2
UUID=${UUID_RESTORE}    /      ext4    defaults,noatime  0       1
EOF

pr_header "copy the recovery image to the recovery /opt dir for restoring"

sync

#sudo dd if=${LOOP_RESTORE}p3 of=mnt/restore_recovery/opt/recovery.img bs=4M
sudo dd bs=4M if=${LOOP_RESTORE}p3 of=recovery.img
sudo zip recovery.img.zip recovery.img
sudo cp recovery.img.zip mnt/restore_recovery/opt/recovery.img.zip

# | sudo zip mnt/restore_recovery/opt/recovery.img.zip -

}


function fix_rootfs_fstab(){


  pr_header "current live fstab"
  cat mnt/restore_rootfs/etc/fstab

  pr_header "map the live fstab to the 3rd partition"

sudo tee mnt/restore_rootfs/etc/fstab << EOF
proc                     /proc  proc    defaults          0       0
UUID=${UUID_BOOT}  /boot  vfat    defaults          0       2
UUID=${UUID_ROOTFS}  /      ext4    defaults,noatime  0       1
EOF

  sync

}

function main(){

  echo "got here"

  make_uuids

  make_looplive_and_mount

  # extract out the boot UUID into var for later use
  get_uuid_for_boot

  make_looprestore_and_mount

  copy_live_to_restore

  overwrite_cmdline_for_boot
  fix_resize_script

  # enable_rpi_serial_console

  # restore triggers the recovery from the running rpi
  make_restore_script

  # @TODO do we want to do this for both the rootfs and recovery.zip?
  fix_rootfs_fstab

  # recovery is triggered after reboot to restore partition
  make_recovery_script


  echo $UUID_BOOT
}