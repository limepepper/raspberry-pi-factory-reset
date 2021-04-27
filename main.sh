#!/bin/bash

# fail on errors, undefined variables, and errors in pipes
set -eu
set -o pipefail

usage()
{
cat << EOF
usage: $0 options
This script run the test1 or test2 over a machine.
OPTIONS:
   -h     Show this message
   -i     source image, from downloads.raspberrypi.org, unzipped
          this file should exist in the current directory
          if not provided this will default to 2021-01-11-raspios-buster-armhf-lite.img
   -c     cleanup and exit. requires -i (or will cleaup default image)
          removes intermediate img files, unmounts loopbacks
          and any mounted img file filesystems
   -e     cleaup at end. generally you want this
   -v      Verbose
EOF
}

DO_CLEANUP_PRE=""
DO_CLEANUP_POST=""
OPTION_BASE=""

while getopts “hcei:p:v” OPTION
do
     case $OPTION in
         h)
            echo "in help"
             usage
             exit 1
             ;;
         c)
             # vvv=$OPTARG
             DO_CLEANUP_PRE=1
            ;;
         e)
             # vvv=$OPTARG
             DO_CLEANUP_POST=1
            ;;
         i)
             # vvv=$OPTARG
             OPTION_BASE=${OPTARG}
            ;;
         ?)
            echo "in usage"
             usage
             exit
             ;;
     esac
done

shift $((OPTIND-1))

source ./display_funcs
source ./setup.sh
source ./utils.sh

check_prerequisites
check_sources

echo "OPTION_BASE is ${OPTION_BASE}"
echo "BASE is $BASE"

if [ ! -z "${DO_CLEANUP_PRE}" ]; then
  cleanup_pre
fi

main

if [ ! -z "${DO_CLEANUP_POST}" ]; then
  cleanup_post
fi

