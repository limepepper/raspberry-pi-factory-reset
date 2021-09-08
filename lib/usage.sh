#!/bin/bash


usage()
{
cat << EOF
usage: $0 options
This script is run to create a Pi OS image with factory reset utility
OPTIONS:
   -i / --image
          The source image.
          This should be an unzipped filesystem image with 2 partitions:
          /boot : following rPi standards, such as having a /boot/cmdline.txt
          / : should be the filesystem that is booted

          generally its best to put this file in the current working directory

   -s     process in steps, outputting useful information and waiting for
          user to confirm before proceeding
   -r     do a cleanup and exit
EOF
}

OPTION_CLEANUP_PRE=""
OPTION_CLEANUP_POST=""
OPTION_BASE=""
OPTION_STEPS=""
OPTION_DO_MAIN=1

OPT_DO_CHECKS=""
OPT_GET_PART_FOR_ORIG="1"
OPT_GET_PART_FOR_LITE="1"
OPT_MAKE_UUIDS="1"
OPT_MOUNT_ORIG="1"
OPT_MOUNT_COPY=""
OPT_COPY_TO_COPY=""
OPT_FIX_ROOTFS_FSTAB=""
OPT_FIX_RESIZE_SCRIPT=""
OPT_MAKE_RECOVERY_ZIP=""
OPT_MOUNT_LITE=""
OPT_GET_RECOVERY_SIZES="1"
OPT_MOUNT_RESTORE=""
OPT_COPY_TO_RESTORE=""

OPT_FIX_CMDLINE_TXT="1"
OPT_MAKE_RESTORE_SCRIPT="1"
OPT_MAKE_RECOVERY_SCRIPT="1"

while getopts “arhcesi:p:v” OPTION
do
     case $OPTION in
         h)
            echo "in help"
             usage
             exit 1
             ;;
         a)
            

            OPTION_CLEANUP_PRE=1
            OPT_DO_CHECKS="1"
            OPT_GET_PART_FOR_ORIG="1"
            OPT_GET_PART_FOR_LITE="1"
            OPT_MAKE_UUIDS="1"
            OPT_MOUNT_ORIG="1"
            OPT_MOUNT_COPY="1"
            OPT_COPY_TO_COPY="1"
            OPT_FIX_ROOTFS_FSTAB="1"
            OPT_FIX_RESIZE_SCRIPT="1"
            OPT_MAKE_RECOVERY_ZIP=""
            OPT_MOUNT_LITE="1"
            OPT_GET_RECOVERY_SIZES="1"
            OPT_MOUNT_RESTORE="1"
            OPT_COPY_TO_RESTORE="1"

            OPT_FIX_CMDLINE_TXT="1"
            OPT_MAKE_RESTORE_SCRIPT="1"
            OPT_MAKE_RECOVERY_SCRIPT="1"

            ;;
         c)
             # vvv=$OPTARG
             OPTION_CLEANUP_PRE=1
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
             OPTION_BASE=${OPTARG}
            ;;
         r)
             # vvv=$OPTARG
             OPTION_CLEANUP_PRE=1
             OPTION_DO_MAIN=""
             OPTION_CLEANUP_POST=""
            ;;
         ?)
            echo "in usage"
             usage
             exit
             ;;
     esac
done

shift $((OPTIND-1))


