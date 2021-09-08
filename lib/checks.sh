


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

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}

function check_sources(){

  pr_header "check sources exist"

  [ -f ${IMG_ORIG} ] && { 
    echo "found ${IMG_ORIG}"
    
  } || { echo "Not found source image '${IMG_ORIG}'" && exit;  }
  [ -f ${RECOVERY_SCRIPT_SOURCE} ] || { echo "Not found ${RECOVERY_SCRIPT_SOURCE}" && exit;  }

  pr_ok "check_sources complete"
  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
}


function check_distribution(){

  pr_header "only support specific releases"

  case $BASE in

  "2018-03-13-raspbian-stretch-lite")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=4028768
    P3_START=4561248
    P3_SIZE=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img2\") .size ")

    OPTION_DO_RESIZE=""


    ;;

  "2020-02-13-raspbian-buster-lite")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=4028768
    P3_START=4561248
    P3_SIZE=3080192

    ;;

  "2021-01-11-raspios-buster-armhf-lite")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=4028768
    P3_START=4561248
    P3_SIZE=3104768

    ;;

  "2021-03-04-raspios-buster-armhf-lite")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=4028768
    P3_START=4561248
    P3_SIZE=3112960
    ;;

  # this is "Raspberry Pi OS with desktop"
  # https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2021-03-25/2021-03-04-raspios-buster-armhf.zip

  "2021-03-04-raspios-buster-armhf")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=9028768
    P3_START=9561248
    P3_SIZE=7217152
    ;;

  # this is "Raspberry Pi OS with desktop"

  "2021-05-07-raspios-buster-armhf")
    pr_ok "distro is $BASE"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=9028768
    P3_START=9561248
    P3_SIZE=7241728
    ;;

  *)
    # this will only work if the zip of the root fs fits in the P2 free space
    # P2 must be at least as big as P3
    pr_warn "not found distro for '$BASE'"
    pr_ok "attempting to determine partition sizes from source"

    P1_START=8192
    P1_SIZE=524288
    P2_START=532480
    P2_SIZE=4028768
    P3_START=4561248
    P3_SIZE=$(sfdisk --json $BASE.img |
          jq ".partitiontable .partitions[] | select(.node == \"${BASE}.img2\") .size ")

    echo "didn't find supported image, so don't have tested partition sizes"
    echo "this might work for lite images, but won't for desktop images"
    read -p "Press enter to continue"
    
      ;;
  esac

  pr_ok "partition values"

cat << EOF
  P1_START=   ${P1_START}
  P1_SIZE=    ${P1_SIZE}
  P2_START=   ${P2_START}
  P2_SIZE=    ${P2_SIZE}
  P3_START=   ${P3_START}
  P3_SIZE=    ${P3_SIZE}
EOF

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
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
  echo "P_END is ${P_END}"
  NEXT_START=$(( ((((( P_END * SECTOR_SIZE ) / BOUNDARY_SIZE) + 1) * BOUNDARY_SIZE) / 512) ))

  echo "NEXT_START = $NEXT_START"

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

  echo "OPTION_BASE          :  ${OPTION_BASE}"
  echo "BASE                 :  $BASE"
  echo "LITE                 :  $LITE"
  echo "IMG_ORIG             :  $IMG_ORIG"
  echo "IMG_ORIG_LITE        :  $IMG_ORIG_LITE"
  echo "IMG_COPY             :  $IMG_COPY"
  echo "IMG_RESTORE          :  $IMG_RESTORE"
  echo "IMG_COPY             :  $IMG_COPY"
  echo "SECTOR_BYTES         :  $SECTOR_BYTES"
  echo "RESIZE_SCRIPT_SOURCE :  $RESIZE_SCRIPT_SOURCE"

  [ -z "${OPTION_STEPS}" ] || { echo ""; read -p "${MSG_CONTINUE}"; }
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