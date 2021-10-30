#/bin/bash

# the option is potentially relative, or a bare filename
# convert this to an absolute file path
IMG_ORIG="$(readlink -f ${OPTION_BASE})"

# the BASE is a path, remove path and file extension
# BASE is basically used by appending suffixes like .copy .restore
# in order to generate intermediate files
BASE=${OPTION_BASE}
BASE="$(basename $BASE)"
BASE="${BASE%.img}"

if [ "$OPT_USE_SLIM" ] ; then
  SLIM=${OPTION_SLIM}
  SLIM="$(basename $SLIM)"
  SLIM="${SLIM%.img}"
  IMG_SLIM="$(readlink -f ${OPTION_SLIM})"
else
  SLIM="${BASE}"
  IMG_SLIM="${IMG_ORIG}"
fi

mkdir -p "${DIR}/tmp"
DIR_TMP="${DIR}/tmp"

mkdir -p "${DIR}/build"
DIR_BUILD="${DIR}/build"

# this is working copy of the original, will be modified and copied again
IMG_COPY="${DIR_TMP}/${BASE}.copy.img"

# this is the ultimate output image that should be used for flashing
IMG_RESTORE="${DIR_BUILD}/${BASE}.restore.img"

# paths to script that is used for resetting in live image
RECOVERY_SCRIPT_SOURCE="${DIR}/init_restore.sh"

# path (in live image, i.e. where to put the file for resizing
RECOVERY_SCRIPT_TARGET=/usr/lib/raspi-config/init_restore.sh

# this is used to fix/debug the resize script
RESIZE_SCRIPT_SOURCE="${DIR}/init_resize.sh"
RESIZE_SCRIPT_TARGET=/usr/lib/raspi-config/init_resize.sh

MOTD_SHOW_LIVE=""
MSG_CONTINUE="...press enter to continue"

# @todo are these still needed?
SECTOR_BYTES=512
SECTOR_SIZE=512
VERBOSITY=2

# number of bytes to pad out the recoveryfs filesystem
PADDING_BYTES=1097152000
