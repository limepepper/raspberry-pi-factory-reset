#!/bin/bash



function check_distribution2(){

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