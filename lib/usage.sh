#!/bin/bash


usage()
{
cat << EOF
usage: $0 options
This script is run to create a Pi OS image with factory reset utility
OPTIONS:
   -a     Run all the steps. Generally you want this unless you are debugging
          some failure somewhere. use with -s for confirmation at each step

   -i     The source image.
          This should be an unzipped filesystem image with 2 partitions:
          /boot : following rPi standards, such as having a /boot/cmdline.txt
          / : should be the filesystem that is booted

          generally its best to put this file in the current working directory

   -l     A slim image  (optional)
          use this option to provide a much smaller partition for the
          recovery filesystem partition

          this should be an unzipped img containing 2 partitions
          usually this will be the lite image corresponding to a desktop
          image

   -s     process in steps, outputting useful information and waiting for
          user to confirm before proceeding

   -c     just do cleaup and exit.
          requires i option to find disks to cleanup

EOF
}

OPT_USE_SLIM=""   # is a slim image provided?


OPTION_CLEANUP_PRE=""       # before starting, cleanup any previous runs
OPTION_CLEANUP_POST=""      # after complete, cleanup loopback and mounts
OPTION_BASE=""              # path to the base image
OPTION_SLIM=""              # path to the slim image
OPTION_STEPS=""             # pause after each step
OPTION_DO_MAIN=""           # unset this to not do the main section

# these are used to override different sections
# mostly for debugging/development
OPT_DO_CHECKS=""            # whether to do file and package checks
OPT_GET_PART_FOR_ORIG=""
OPT_GET_PART_FOR_SLIM=""    # get the slim image partition sizes
OPT_MAKE_UUIDS=""
OPT_MOUNT_ORIG=""
OPT_MOUNT_COPY=""
OPT_COPY_TO_COPY=""
OPT_FIX_ROOTFS_FSTAB=""
OPT_FIX_RESIZE_SCRIPT=""
OPT_MAKE_RECOVERY_ZIP=""
OPT_MOUNT_SLIM=""
OPT_GET_RECOVERY_SIZES=""
OPT_MOUNT_RESTORE=""
OPT_COPY_TO_RESTORE=""
OPT_FIXUP_RECOVERY_ROOTFS=""

OPT_FIX_CMDLINE_TXT=""
OPT_MAKE_RESTORE_SCRIPT=""
OPT_MAKE_RECOVERY_SCRIPT=""

OPT_POST_SUMMARY=""

OPT_RUN_TESTS=""

# no idea what half of these options were supposed to do
# would be nice to switch to something that handled long opts

while getopts “arhcsi:l:p:vetz” OPTION
do
     case $OPTION in
         h)
           # echo "in help"
           usage
           exit 1
        ;;
         a)

            OPTION_CLEANUP_PRE=1
            OPT_DO_CHECKS="1"
            OPT_GET_PART_FOR_ORIG="1"
            OPT_MAKE_UUIDS="1"
            OPT_MOUNT_ORIG="1"
            OPT_MOUNT_COPY="1"
            OPT_COPY_TO_COPY="1"
            OPT_FIX_ROOTFS_FSTAB="1"
            OPT_FIX_RESIZE_SCRIPT="1"
            OPT_MAKE_RECOVERY_ZIP="1"
            OPT_GET_RECOVERY_SIZES="1"
            OPT_MOUNT_RESTORE="1"
            OPT_COPY_TO_RESTORE="1"

            OPT_FIX_CMDLINE_TXT="1"
            OPT_MAKE_RESTORE_SCRIPT="1"
            OPT_MAKE_RECOVERY_SCRIPT="1"
            OPT_FIXUP_RECOVERY_ROOTFS="1"

            #
            OPT_GET_PART_FOR_SLIM="1"
            OPT_MOUNT_SLIM="1"

            OPT_POST_SUMMARY="1"

            OPTION_CLEANUP_POST="1"

          ;;
         c)
             # vvv=$OPTARG
             OPTION_CLEANUP_PRE=1
             OPTION_CLEANUP_POST=""
          ;;
         e)
             # vvv=$OPTARG
             OPTION_CLEANUP_POST=0
          ;;
         s)
             # vvv=$OPTARG
             OPTION_STEPS=1
          ;;
         i)
             # vvv=$OPTARG
             # echo "processing i option"
             OPTION_BASE=${OPTARG}
          ;;
         l)
            # vvv=$OPTARG
            # echo "processing l option"
            OPTION_SLIM=${OPTARG}
            OPT_USE_SLIM=1
            OPT_GET_PART_FOR_SLIM="1"
            OPT_MOUNT_SLIM="1"
         ;;
         # don't do slow operations, used for testing
         z)
            OPT_MAKE_RECOVERY_ZIP=""
         ;;
         # run tests and exit
         t)
            OPT_RUN_TESTS="1"
          break  # don't process any more options
         ;;
         ?)
            # echo "in usage"
            usage
            exit
          ;;
     esac
done

shift $((OPTIND-1))

if [ ! "${OPTION_BASE}" ] ; then
    echo "-i     The source image is required."
    echo "${MAGENTAFG} OPTION_BASE is required ${RESET}"
    echo ""
    usage
    exit 1
fi

if [ ! -f "${OPTION_BASE}" ] ; then
    echo "${ORANGEFG} the source image must exist ${RESET}"
    ls "${OPTION_BASE}" || true
    echo
    usage
    exit 1
fi

if [ "$OPT_USE_SLIM" ] ; then
  if [ ! -f "${OPTION_SLIM}" ] ; then
    echo "${ORANGEFG} if -l is given slim image must exist ${RESET}"
    ls "${OPTION_SLIM}" || true
    echo
    usage
    exit 1
  fi
fi
