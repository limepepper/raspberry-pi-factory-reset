
function get_partitions_for_original(){

  ORIG_P1_START=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img1\") .start ")

  ORIG_P1_SIZE=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img1\") .size ")

  ORIG_P2_START=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img2\") .start ")

  ORIG_P2_SIZE=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img2\") .size ")

}
function get_partitions_for_lite(){

  LITE_P1_START=$(sfdisk --json ${LITE}.img |
          jq ".partitiontable .partitions[] | select(.node == \"${LITE}.img1\") .start ")

  LITE_P1_SIZE=$(sfdisk --json $LITE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${LITE}.img1\") .size ")

  LITE_P2_START=$(sfdisk --json $LITE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${LITE}.img2\") .start ")

  LITE_P2_SIZE=$(sfdisk --json $LITE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${LITE}.img2\") .size ")

}


function show_base_infos(){
  pr_header "show base image infos"


  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}


function cleanup()
{

  pr_header "cleanup devices, mounts, etc"

  pr_section "sync'ing filesystem"
  # no idea if this makes any difference???
  sync

  pr_section "unmounting restore filesystems"

  sudo umount -d mnt/restore_boot > /dev/null 2>&1 || true
  sudo umount -d mnt/restore_rootfs > /dev/null 2>&1 || true
  sudo umount -d mnt/restore_recovery > /dev/null 2>&1 || true

  pr_section "detaching any loopback devices"

  for imgname in $IMG_RESTORE $IMG_ORIG $IMG_ORIG_LITE $IMG_COPY; do
    echo "unounting $imgname"
    if [ -e "$IMG_ORIG_LITE" ] ; then
      while losetup -a | grep "${imgname}" > /dev/null 2>&1; do
        TMPLOOP="$(losetup -a | grep "${imgname}" | head -1| awk '{ print $1 }')"
        TMPLOOP=${TMPLOOP%:}
        echo $TMPLOOP
        sudo losetup --detach ${TMPLOOP}
        echo "detached ${TMPLOOP}"
      done
    fi
  done

  # Perform a garbage collection pass on the blkid cache to remove devices
  # which no longer exist
  sudo blkid --garbage-collect

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}




# generate new UUIDs for the copy of the original image
function make_uuids(){

  pr_header "make UUID/partuuids for restore filesystems"

  # partuuid seems to get reset by resize.sh, however UUID doesn't seem to work
  set +o pipefail
  PARTUUID=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)
  set -o pipefail

  [ ! -z ${PARTUUID} ] || { echo "PARTUUID is empty '${PARTUUID}'" && exit 99;  }

  set +o pipefail
  COPY_PARTUUID=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)
  set -o pipefail

  [ ! -z ${COPY_PARTUUID} ] || { echo "COPY_PARTUUID is empty '${COPY_PARTUUID}'" && exit 99;  }

  # because of cloning the images, need to generate new UUIDs
  UUID_RESTORE=$(uuidgen)
  [ ! -z "$UUID_RESTORE" ] || { echo "UUID_RESTORE Empty: can't proceed"; exit 99; }
  UUID_ROOTFS=$(uuidgen)
  [ ! -z "$UUID_ROOTFS" ] || { echo "UUID_ROOTFS Empty: can't proceed"; exit 99; }
  UUID_COPY_ROOTFS=$(uuidgen)
  [ ! -z "$UUID_COPY_ROOTFS" ] || { echo "UUID_COPY_ROOTFS Empty: can't proceed"; exit 99; }

  pr_ok "PARTUUID:          ${PARTUUID}"
  pr_ok "COPY_PARTUUID:     ${COPY_PARTUUID}"
  pr_ok "UUID_RESTORE:      ${UUID_RESTORE}"
  pr_ok "UUID_ROOTFS:       ${UUID_ROOTFS}"
  pr_ok "UUID_COPY_ROOTFS:  ${UUID_COPY_ROOTFS}"

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

# make a copy of the original img file
# mounts the partitions from the new img onto loopback devices
#
function make_loop_and_mount_original(){

  pr_header "mount the original img readonly on loopback"

  pr_ok "show source image partition (from sfdisk --dump"
  sfdisk -d $IMG_ORIG

  LOOP_ORIG=$(sudo losetup \
        --read-only \
        --nooverlap \
        --show \
        --find \
        --partscan \
           ${IMG_ORIG})
           
  [ ! -z "$LOOP_ORIG" ] || { echo "LOOP_ORIG Empty: can't proceed"; exit 99; }

  echo "The Original img is mounted readonly at ${LOOP_ORIG}"
  sudo partprobe ${LOOP_ORIG}
  echo ""

  UUID_BOOT="$(sudo blkid -s UUID -o value ${LOOP_ORIG}p1)"
  [ ! -z "$UUID_BOOT" ] || { echo "UUID_BOOT Empty: can't proceed"; exit 99; }

  # cat /proc/partitions
  # sudo losetup -a
  # sudo blkid
  # echo ""

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

function make_loop_and_mount_lite(){

  pr_header "mount the liteversion of img readonly on loopback"

  pr_ok "show source image partition (from sfdisk --dump)"
  sfdisk -d $IMG_ORIG_LITE

  LOOP_ORIG_LITE=$(sudo losetup \
        --read-only \
        --nooverlap \
        --show \
        --find \
        --partscan \
           ${IMG_ORIG_LITE})
  [ ! -z "$IMG_ORIG_LITE" ] || { echo "IMG_ORIG_LITE Empty: can't proceed"; exit 99; }

  echo "The Original LITE img is mounted readonly at ${LOOP_ORIG_LITE}"
  sudo partprobe ${LOOP_ORIG_LITE}
  echo ""

  UUID_BOOT_LITE="$(sudo blkid -s UUID -o value ${LOOP_ORIG_LITE}p1)"
  [ ! -z "$UUID_BOOT_LITE" ] || { echo "UUID_BOOT Empty: can't proceed"; exit 99; }

  # cat /proc/partitions
  # sudo losetup -a
  # sudo blkid
  # echo ""

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

function make_loop_and_mount_copy(){

  pr_header "make img copy and mount it"

# this could also be dynamically determined, but needs partition 2 to be
# large enough to fit a zipped copy of partiion 3 for restoring
# so these are just hard coded based on trial and error per Pi OS release

  tmpfile=$(mktemp /tmp/reset_sfdisk.XXXXXX)

cat << EOF > ${tmpfile}
label: dos
label-id: 0x${COPY_PARTUUID}
unit: sectors

${IMG_COPY}1 : start=${ORIG_P1_START},     size=${ORIG_P1_SIZE},    type=c
${IMG_COPY}2 : start=${ORIG_P2_START},   size=${ORIG_P2_SIZE},   type=83

EOF

find_boundary ${ORIG_P2_START} ${ORIG_P2_SIZE}

echo "found boundary at $REPLY"



  # final sector of filesystem
  END_BEFORE_BOUNDARY=$(( REPLY + 10 ))

  echo "END_BEFORE_BOUNDARY is $END_BEFORE_BOUNDARY"

  # TOTAL_SIZE_BYTES=$(( END_BEFORE_BOUNDARY * SECTOR_BYTES ))

  # echo "TOTAL_SIZE_BYTES is $TOTAL_SIZE_BYTES"

  # exit

  [[ -f "${IMG_COPY}" ]] && \
  {
    pr_warn "IMG_COPY file ${IMG_COPY} already, exists - overwriting"
  } || \
  {
    pr_ok "restore file ${IMG_RESTORE} creating"
    # touch ${IMG_RESTORE}
  }

  echo $IMG_COPY
  echo "creating ${END_BEFORE_BOUNDARY} blocks of 512 bytes"

  

  dd if=/dev/zero bs=512 count=${END_BEFORE_BOUNDARY} > ${IMG_COPY}

  # fdisk -l ${IMG_RESTORE}

  echo "writing partition table"
  cat "$tmpfile"

  sfdisk ${IMG_COPY} < "$tmpfile"

  
  #rm "$tmpfile"

  fdisk -lu ${IMG_COPY}

  LOOP_COPY=$(sudo losetup -v  --show -f -P ${IMG_COPY})

  [ ! -z "$LOOP_COPY" ] || { echo "LOOP_COPY Empty: can't proceed"; exit 99; }

  pr_ok "partprobe the new loopback device - ${LOOP_COPY}"
  sudo partprobe ${LOOP_COPY}

  pr_ok "show the partitions"
  losetup -a

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}


function copy_original_to_copy(){

  pr_header "3.4 copy the filesystem partitions to the restore img"

  sudo dd if=${LOOP_ORIG}p1 of=${LOOP_COPY}p1 bs=4M
  sudo dd if=${LOOP_ORIG}p2 of=${LOOP_COPY}p2 bs=4M

  # make sure the partitions on the loop device are available
  sudo partprobe ${LOOP_COPY}

  pr_ok "3.6 call tunefs to set label and UUID"

  # echo $UUID_RESTORE
  # echo $LOOP_RESTORE

  sudo tune2fs ${LOOP_COPY}p2 -U ${UUID_COPY_ROOTFS}
  sudo e2label ${LOOP_COPY}p2 copyroot

  pr_ok "3.7 call partprobe"
  sudo partprobe ${LOOP_COPY}

  pr_ok "3.8 resize the fs on the recovery partition to fit the restore img"

  sudo e2fsck -f ${LOOP_COPY}p2

  sudo fdisk -l ${LOOP_COPY}

  mkdir -p mnt/copy_boot
  mkdir -p mnt/copy_rootfs

  sudo mount ${LOOP_COPY}p1 mnt/copy_boot
  sudo mount ${LOOP_COPY}p2 mnt/copy_rootfs

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}

# the restore img is the file that contains the partitions that will
# ultimately get written out to the sdcard
function make_loop_and_mount_restore(){

  pr_header "make img restore and mount it"

# this could also be dynamically determined, but needs partition 2 to be
# large enough to fit a zipped copy of partiion 3 for restoring
# so these are just hard coded based on trial and error per Pi OS release

  tmpfile=$(mktemp /tmp/reset_sfdisk.XXXXXX)

cat << EOF > ${tmpfile}
label: dos
label-id: 0x${PARTUUID}
unit: sectors

${IMG_RESTORE}1 : start=${P1_START},     size=${P1_SIZE},    type=c
${IMG_RESTORE}2 : start=${P2_START},   size=${P2_SIZE},   type=83
${IMG_RESTORE}3 : start=${P3_START},  size=${P3_SIZE},   type=83

EOF

  # final sector of filesystem
  P3_END=$(( P3_START + P3_SIZE - 1 ))
  TOTAL_SIZE_BYTES=$(( P3_END * SECTOR_BYTES ))
  BLOCKSIZE=$(( 1024 * 1024 * 4 ))
  BSCOUNT=$(( TOTAL_SIZE_BYTES / BLOCKSIZE ))
  echo "BSCOUNT: $BSCOUNT"


  if [ $(( TOTAL_SIZE_BYTES % BLOCKSIZE )) -ne 0 ]; then
    BSCOUNT=$(( BSCOUNT + 1 ))
  else
    #BSCOUNT=$(( TOTAL_SIZE_BYTES / BLOCKSIZE ))
    echo "BS COUNT remainder was zero"
  fi

  echo "remainder: $(( TOTAL_SIZE_BYTES % BLOCKSIZE ))"
  echo "BLOCKSIZE: $BLOCKSIZE"
  echo "TOTAL SIZE BYTES: $TOTAL_SIZE_BYTES"
  echo "P3_END: $P3_END"
  echo "BSCOUNT: $BSCOUNT"

  [[ -f "${IMG_RESTORE}" ]] && \
  {
    pr_warn "restore file ${IMG_RESTORE} already, exists - overwriting"
  } || \
  {
    pr_ok "restore file ${IMG_RESTORE} creating"
    # touch ${IMG_RESTORE}
  }

  dd if=/dev/zero bs=4M count=${BSCOUNT} > ${IMG_RESTORE}

  # fdisk -l ${IMG_RESTORE}

  sfdisk ${IMG_RESTORE} < "$tmpfile"

  cat "$tmpfile"
  #rm "$tmpfile"

  fdisk -lu ${IMG_RESTORE}

  LOOP_RESTORE=$(sudo losetup -v  --show -f -P ${IMG_RESTORE})
  [ ! -z "$LOOP_RESTORE" ] || { echo "LOOP_RESTORE Empty: can't proceed"; exit 99; }

  pr_ok "partprobe the new loopback device - ${LOOP_RESTORE}"
  sudo partprobe ${LOOP_RESTORE}

  pr_ok "show the partitions"
  losetup -a

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}

function copy_original_to_restore(){

  pr_header "3.4 copy the filesystem partitions to the restore img"

  sudo dd if=${LOOP_ORIG}p1 of=${LOOP_RESTORE}p1 bs=4M
  sudo dd if=${LOOP_ORIG}p2 of=${LOOP_RESTORE}p2 bs=4M
  sudo dd if=${LOOP_ORIG}p2 of=${LOOP_RESTORE}p3 bs=4M

  # make sure the partitions on the loop device are available
  sudo partprobe ${LOOP_RESTORE}

  pr_ok "3.6 call tunefs to set label and UUID"

  # echo $UUID_RESTORE
  # echo $LOOP_RESTORE

  sudo tune2fs ${LOOP_RESTORE}p2 -U ${UUID_RESTORE}
  sudo e2label ${LOOP_RESTORE}p2 recoveryfs

  sudo tune2fs ${LOOP_RESTORE}p3 -U ${UUID_ROOTFS}

  pr_ok "3.7 call partprobe"
  sudo partprobe ${LOOP_RESTORE}

  pr_ok "3.8 resize the fs on the recovery partition to fit the restore img"

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

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}

function overwrite_cmdline_for_boot(){

  pr_header "4.0 current boot cmdline.txt"

  pr_ok "current cmdline.txt is"
  cat mnt/restore_boot/cmdline.txt

  pr_ok "saving original cmdline.txt"
  sudo cp mnt/restore_boot/cmdline.txt mnt/restore_boot/cmdline.txt_from_pristine

  pr_ok "4.1 create the boot from live rootfs cmdline.txt"

sudo tee mnt/restore_boot/cmdline.txt << EOF
console=serial0,115200 console=tty1 root=PARTUUID=${PARTUUID}-03 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait init=/usr/lib/raspi-config/init_resize.sh
EOF

  pr_ok "4.3 create alt cmd file for recovery boot"

sudo tee mnt/restore_boot/cmdline.txt_recovery << EOF
console=serial0,115200 console=tty1 root=PARTUUID=XXXYYYXXX rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=${RECOVERY_SCRIPT_TARGET}
EOF

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }

}

# doesn't wait for error message
function fix_resize_script(){

  pr_header "fix_resize_script"

  pr_ok "copy the custom init_resize.sh into rootfs"

  sudo cp "${RESIZE_SCRIPT_SOURCE}" "mnt/restore_rootfs${RESIZE_SCRIPT_TARGET}"
  sudo chmod +x "mnt/restore_rootfs${RESIZE_SCRIPT_TARGET}"

  sync

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
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

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

function make_restore_script(){
#   ___        _               ___         _      _
#  | _ \___ __| |_ ___ _ _ ___/ __| __ _ _(_)_ __| |_
#  |   / -_|_-<  _/ _ \ '_/ -_)__ \/ _| '_| | '_ \  _|
#  |_|_\___/__/\__\___/_| \___|___/\__|_| |_| .__/\__|
#                                           |_|

  pr_header "4.4 create factory reset script in /boot directory"

sudo tee mnt/restore_boot/factory_reset > /dev/null << EOF
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

  # echo "show blkid"
  # blkid
  # echo ""

  echo "show rootfs fstab"
  cat /etc/fstab
  echo ""

  # echo "show recoveryfs fstab"
  # mkdir -p /mnt/recoveryfs
  # mount /dev/disk/by-label/recoveryfs /mnt/recoveryfs
  # cat /mnt/recoveryfs/etc/fstab

  umount -f /mnt/recoveryfs
  echo ""

  echo "show current cmdline.txt"
  cat /boot/cmdline.txt
  echo ""

  echo "rebooting..."
  reboot
  exit 0
}

EOF

  sudo chmod +x mnt/restore_boot/factory_reset

  pr_ok "copy init_restore.sh to recovery"
  sudo cp "${RECOVERY_SCRIPT_SOURCE}" "mnt/restore_recovery${RECOVERY_SCRIPT_TARGET}"
  sudo chmod +x "mnt/restore_recovery${RECOVERY_SCRIPT_TARGET}"

  pr_ok "current boot cmdline.txt"
  cat mnt/restore_boot/cmdline.txt

  pr_ok "current boot cmdline.txt txt_recovery"
  cat mnt/restore_boot/cmdline.txt_recovery

  pr_ok "enable ssh on the image"
  sudo touch mnt/restore_boot/ssh

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}


function make_recovery_script(){

  pr_header "current recovery fstab"
  cat mnt/restore_recovery/etc/fstab

  pr_ok "indicate this is a recovery shell"

# not sure this is getting used on the console...?
sudo tee mnt/restore_recovery/etc/motd << EOF
##    ____  _____ ____ _____     _______ ______   __
##   |  _ \| ____/ ___/ _ \ \   / / ____|  _ \ \ / /
##   | |_) |  _|| |  | | | \ \ / /|  _| | |_) \ V /
##   |  _ <| |__| |__| |_| |\ V / | |___|  _ < | |
##   |_| \_\_____\____\___/  \_/  |_____|_| \_\|_|
##
EOF

pr_ok "map the recovery fstab to the 2nd partition"
sudo tee mnt/restore_recovery/etc/fstab << EOF
proc                    /proc  proc    defaults          0       0
UUID=${UUID_BOOT}       /boot  vfat    defaults          0       2
UUID=${UUID_RESTORE}    /      ext4    defaults,noatime  0       1
EOF

pr_ok "copy the recovery image to the recovery /opt dir for restoring"

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

  pr_ok "map the live fstab to the 3rd partition"

sudo tee mnt/restore_rootfs/etc/fstab << EOF
proc                     /proc  proc    defaults          0       0
UUID=${UUID_BOOT}  /boot  vfat    defaults          0       2
UUID=${UUID_ROOTFS}  /      ext4    defaults,noatime  0       1
EOF

  sync

}

die () {
    echo >&2 "$@"
    exit 1
}

# parameters: takes $start and $size parameters in sectors.
# description: 
# 
function find_boundary(){
  [ "$#" -eq 2 ] || die "need 2 arguments"
  start=$1
  size=$2

  SECTOR_SIZE=512    # bytes
  BOUNDARY_SIZE=8192  # bytes


  P_END=$(( start + size - 1 ))
  echo "P_END is ${P_END}"
  NEXT_START=$(( ((((( P_END * SECTOR_SIZE ) / BOUNDARY_SIZE) + 1) * BOUNDARY_SIZE) / 512) ))

  echo "NEXT_START = $NEXT_START"

  REPLY=$NEXT_START
}

function get_sectors_for_bytes(){
  [ "$#" -eq 1 ] || die "need 1 argument"
  size=$1

  SECTOR_SIZE=512    # bytes

  if [ "$(( size % SECTOR_SIZE ))" -eq 0 ] ;then
    SECTOR_COUNT=$(( size / SECTOR_SIZE ))
  else
    SECTOR_COUNT=$(( ( size / SECTOR_SIZE) + 1 ))
  fi
  
  echo "SECTOR_COUNT= $SECTOR_COUNT"

  REPLY=$SECTOR_COUNT
}

function main(){

  echo "got here"

  make_uuids

  make_loop_and_mount_original

  make_loop_and_mount_restore

  copy_original_to_restore

  overwrite_cmdline_for_boot

  [ -z "${OPTION_DO_RESIZE}" ] || fix_resize_script

  # enable_rpi_serial_console

  # restore triggers the recovery from the running rpi
  make_restore_script

  # @TODO do we want to do this for both the rootfs and recovery.zip?
  fix_rootfs_fstab

  # recovery is triggered after reboot to restore partition
  make_recovery_script

}