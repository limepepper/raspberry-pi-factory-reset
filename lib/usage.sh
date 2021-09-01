#!/bin/bash


usage()
{
cat << EOF
usage: $0 options
This script is run to create a Pi OS image with factory reset utility
OPTIONS:
   -h     Show this message
   -i     source image, from downloads.raspberrypi.org, unzipped (optional)
          this file should exist in the current directory
          if not provided this will default to 2021-01-11-raspios-buster-armhf-lite.img
   -s     process in steps, outputting useful information and waiting for
          user to confirm before proceeding
   -r     do a cleanup and exit
EOF
}

OPTION_CLEANUP_PRE="1"
OPTION_CLEANUP_POST="1"
OPTION_BASE=""
OPTION_STEPS=""
OPTION_DO_MAIN=1

while getopts “rhcesi:p:v” OPTION
do
     case $OPTION in
         h)
            echo "in help"
             usage
             exit 1
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


