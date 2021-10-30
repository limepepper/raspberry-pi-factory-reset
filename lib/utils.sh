
spacefiller='                           '

# this tries to extract and display values produced by blkid
parse_blkid_var(){

  [ "$#" -eq 4 ] || die "need 4 arguments"
  local varname=$1
  local devname=$2
  local prefix=$3
  local value=$4

  # local varname="${prefix}_UUID_BOOT"
  # blkid -p references the low level superblock
  # blkid -g refreshes the cache
  declare -r -g "${varname}"="$(blkid -s ${value} -o value ${devname})"
  [ ! -z "${!varname}" ] || {
    pr_alert "${varname} Empty: can't proceed at ${BASH_LINENO}"
    blkid ${devname}
    echo $varname
    echo $devname
    pr_val prefix
    pr_val value
    pr_red "if the partuuid is missing, it seemed to be because something was"
    pr_red "left mounted. unmounting all loop devices, and removing images from"
    pr_red "loopback devices seemed to fix it"
    exit 99

    }
  # echo "${varname}         : ${!varname}"
  printf '%s\n' "$GREEN$varname${spacefiller:${#varname}}$RESET : $ORANGEFG${!varname}$RESET"

}

# this is a utility function to extract and display the various UUID
# types etc for a loopback device
inspect_loop_device(){

  [ "$#" -eq 2 ] || die "need 2 arguments"

  local device=$1
  local prefix=$2

  blkid -g

  parse_blkid_var "${prefix}_PTTYPE" "${device}" "$prefix" "PTTYPE"
  parse_blkid_var "${prefix}_PTUUID" "${device}" "$prefix" "PTUUID"

  parse_blkid_var "${prefix}_UUID_BOOT" "${device}p1" "$prefix" "UUID"

  if [ ! -e "${device}p3" ] ; then
    parse_blkid_var "${prefix}_UUID_ROOT"    "${device}p2" "$prefix" "UUID"
  else
    parse_blkid_var "${prefix}_UUID_RESTORE" "${device}p2" "$prefix" "UUID"
    parse_blkid_var "${prefix}_UUID_ROOT"    "${device}p3" "$prefix" "UUID"
  fi

  parse_blkid_var "${prefix}_PARTUUID_BOOT" "${device}p1" "$prefix" "PARTUUID"

  if [ ! -e "${device}p3" ] ; then
    parse_blkid_var "${prefix}_PARTUUID_ROOT" "${device}p2" "$prefix" "PARTUUID"
  else
    parse_blkid_var "${prefix}_PARTUUID_RESTORE" "${device}p2" "$prefix" "PARTUUID"
    parse_blkid_var "${prefix}_PARTUUID_ROOT"    "${device}p3" "$prefix" "PARTUUID"
  fi

  # this not working on Ubuntu 20.04
  # # blkid --version
  # blkid from util-linux 2.34  (libblkid 2.34.0, 14-Jun-2019)

  # parse_blkid_var "${prefix}_BLOCK_SIZE_BOOT" "${device}p1" "$prefix" "BLOCK_SIZE"

  # if [ ! -e "${device}p3" ] ; then
  #   parse_blkid_var "${prefix}_BLOCK_SIZE_ROOT" "${device}p2" "$prefix" "BLOCK_SIZE"
  # else
  #   parse_blkid_var "${prefix}_BLOCK_SIZE_RESTORE" "${device}p2" "$prefix" "BLOCK_SIZE"
  #   parse_blkid_var "${prefix}_BLOCK_SIZE_ROOT"    "${device}p3" "$prefix" "BLOCK_SIZE"
  # fi
  echo ""
}

step_pause(){

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; echo ""; }
  echo ""
}

debug_pause(){

  if [ $VERBOSITY -gt 1 ] ; then
    echo ""
    read -p "${MSG_CONTINUE}"
    echo ""
  fi
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
      jq
  )

  for cmd in "${cmds[@]}"; do
    if ! command -v ${cmd} > /dev/null; then
      echo "need command \"${cmd}\" installed... exiting"
      exit 99
    else
      echo -n "${cmd}.."
    fi
  done
  echo ""

  pr_ok "found necessary utilites in path"
  echo

  # [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

function check_sources(){

  pr_header "check sources exist"

  [ -f ${IMG_ORIG} ] && {
    echo "found ${IMG_ORIG}"

  } || { echo "Not found source image '${IMG_ORIG}'" && exit;  }

  [ -f ${RECOVERY_SCRIPT_SOURCE} ] || { echo "Not found ${RECOVERY_SCRIPT_SOURCE}" && exit;  }

  pr_ok "check_sources complete"
  echo

  # [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

# parameters: takes $start and $size parameters in sectors.
# description:
#
function find_boundary(){
  [ "$#" -eq 2 ] || die "need 2 arguments"
  start=$1
  size=$2

  BOUNDARY_SIZE=8192  # bytes


  P_END=$(( start + size - 1 ))
  pr_kv "P_END : ${P_END}"
  NEXT_START=$(( ((((( P_END * SECTOR_SIZE ) / BOUNDARY_SIZE) + 1) * BOUNDARY_SIZE) / 512) ))

  pr_kv "NEXT_START : $NEXT_START"

  REPLY=$NEXT_START
}

# given a start and size in sectors, calculate the bytes required for the
# image file to contain this
function get_bytes_to_contain_partition(){
  [ "$#" -eq 2 ] || die "need 2 arguments"
  start=$1
  size=$2

  REPLY=$(( ( start + size ) * 512 ))
}

# given a number of bytes find the number of sectors to allocate to contain
# that amount of stuff
function round_bytes_to_sectors(){
  [ "$#" -eq 1 ] || die "need 1 arguments"
  bytecount=$1

  if [ "$(( bytecount % SECTOR_SIZE ))" -eq 0 ] ; then
    REPLY="$(( bytecount / SECTOR_SIZE ))"
  else
    REPLY="$(( ( bytecount / SECTOR_SIZE ) + 1 ))"
  fi

}

# given sectors return number of bytes
function sectors_to_bytes(){
  [ "$#" -eq 1 ] || die "need 1 arguments"
  local SECTOR_COUNT=$1

  REPLY=$(( SECTOR_COUNT * SECTOR_SIZE ))
}

function show_setup_var_summary(){
  pr_header "summary of setup variables"

  pr_kv "OPTION_BASE          :  ${OPTION_BASE}"
  pr_kv "BASE                 :  $BASE"
  pr_kv "IMG_ORIG             :  $IMG_ORIG"
  echo ""

  pr_kv "IMG_COPY             :  $IMG_COPY"
  pr_kv "IMG_RESTORE          :  $IMG_RESTORE"

  pr_kv "SECTOR_BYTES         :  $SECTOR_BYTES"
  pr_kv "RESIZE_SCRIPT_SOURCE :  $RESIZE_SCRIPT_SOURCE"

  if [ ! "$OPT_USE_SLIM" ] ; then
    echo
    pr_warn "only BASE image provided, so using base p2 as the recovery partition"
  fi
  pr_kv "OPTION_SLIM          :  ${OPTION_SLIM}"
  pr_kv "SLIM                 :  $SLIM"
  pr_kv "IMG_SLIM             :  $IMG_SLIM"
  echo ""

  step_pause
}

function bytes_to_blocks(){
  [ "$#" -eq 1 ] || die "need 1 arguments"
  local BYTE_COUNT=$1

  if [ "$(( BYTE_COUNT % 8192 ))" -eq 0 ] ; then
    REPLY="$(( BYTE_COUNT / 8192 ))"
  else
    REPLY="$(( ( BYTE_COUNT / 8192 ) + 1 ))"
  fi
}

# inspects an fstab formatted file and takes values for UUID and PARTUUD for
# /boot and / partitions, it fixes up the file for the new values
# preserving other formatting
function fixup_fstab(){
  [ "$#" -eq 5 ] || die "need 5 arguments"

  local fstab_file=$1
  local boot_partuuid=$2
  local boot_uuid=$3
  local root_partuuid=$4
  local root_uuid=$5

  if [ ! -f "$fstab_file" ] ; then
    echo "$fstab_file is not a file"
    exit 99
  fi

  # basically 4 cases, either PARTUUID= or UUID= for both /boot and /
  # there is probably a better way to do this

  # something to track whether the value was fixed by one or other replacement
  local fixed_boot=""
  local fixed_root=""

  # if /boot device mount was referenced by a partuuid
  if egrep '^PARTUUID=' "$fstab_file" | grep '/boot' ; then
    pr_debug "/boot was a PARTUUID"
    sed -i -E "s|^PARTUUID=([^[:space:]]+)[[:space:]]+/boot([[:space:]]+)(.*)|PARTUUID=${boot_partuuid}      /boot     \3|" "$fstab_file"
    fixed_boot=1
  fi

  # if /boot device mount was referenced by a uuid
  if egrep '^UUID=' "$fstab_file" | grep '/boot' ; then
    pr_debug "/boot was a UUID"
    sed -i -E "s|^UUID=([^[:space:]]+)[[:space:]]+/boot([[:space:]]+)(.*)|UUID=${boot_uuid}      /boot     \3|" "$fstab_file"
    fixed_boot=1
  fi

  # if / device mount was referenced by a partuuid
  if egrep '^PARTUUID=' "$fstab_file" | egrep '[[:space:]]/[[:space:]]' ; then
    pr_debug "/ was a PARTUUID"
    sed -i -E "s|^PARTUUID=([^[:space:]]+)[[:space:]]+/([[:space:]]+)(.*)|PARTUUID=${root_partuuid}      /     \3|" "$fstab_file"
    fixed_root=1
  fi

  # check that / device mount was referenced by a uuid
  if egrep '^UUID=' "$fstab_file" | egrep '[[:space:]]/[[:space:]]' ; then
    pr_debug "/ was a UUID"
    sed -i -E "s|^UUID=([^[:space:]]+)[[:space:]]+/([[:space:]]+)(.*)|UUID=${root_partuuid}      /     \3|" "$fstab_file"
    fixed_root=1
  fi

    echo
    echo

}


# rmeove any of the mounts of loopback devices
# also unmount images from loopback devices
function cleanup()
{

  pr_header "cleanup devices, mounts, etc"

  pr_h2 "sync'ing filesystem"
  # no idea if this makes any difference???
  sync

   pr_h2 "unmounting restore filesystems"

  {
   for foo in copy_rootfs \
                slim_rootfs \
                restore_boot \
                restore_rootfs \
                restore_recovery; do
  umount -v -d "mnt/${foo}" || true
  done

  } | pr_section "unmounin"

#> /dev/null 2>&1

  pr_section "detaching any loopback devices" < <(
  for imgname in $IMG_RESTORE $IMG_ORIG $IMG_SLIM $IMG_COPY; do
    # echo "unounting $imgname"
    if [ -e "$imgname" ] ; then
      while losetup -a | grep "${imgname}" > /dev/null 2>&1; do
        TMPLOOP="$(losetup -a | grep "${imgname}" | head -1| awk '{ print $1 }')"
        TMPLOOP=${TMPLOOP%:}
        # echo $TMPLOOP
        losetup --detach ${TMPLOOP}
        echo "detached ${TMPLOOP}"
      done
    fi
  done
  )

  # if [ -f "${IMG_COPY}" ] ; then
  #   rm "${IMG_COPY}"
  # fi

  # Perform a garbage collection pass on the blkid cache to remove devices
  # which no longer exist
  blkid --garbage-collect

  if [ -d "$DIR/tmp" ] ; then
    find "$DIR/tmp" -type f -exec rm '{}' \;
  fi

  step_pause

}
