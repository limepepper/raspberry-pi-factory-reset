

# DEFAULT_BASE=2018-03-13-raspbian-stretch-lite
# DEFAULT_BASE=2018-06-27-raspbian-stretch-lite
# DEFAULT_BASE=2018-10-09-raspbian-stretch-lite
DEFAULT_BASE=2021-05-07-raspios-buster-armhf-lite
DEFAULT_LITE=2021-05-07-raspios-buster-armhf-lite

BASE=${OPTION_BASE:-$DEFAULT_BASE}

# if the BASE is a path, remove path and extension
BASE="$(basename $BASE)"
BASE="${BASE%.img}"

LITE=${OPTION_LITE:-$DEFAULT_LITE}
LITE="$(basename $LITE)"
LITE="${LITE%.img}"

# echo $BASE
# echo $LITE

# echo "base DIR is ${DIR}"

# paths for base, intermediate and restore images

# this is the source
IMG_ORIG="${DIR}/${BASE}.img"
IMG_LITE="${DIR}/${LITE}.img"

# this is working copy of the original, will be modified and copied again
IMG_COPY="${DIR}/${BASE}.copy.img"

# this is the ultimate output image that should be used for flashing
IMG_RESTORE="${DIR}/${BASE}.restore.img"

# paths to script that is used for resetting in live image
RECOVERY_SCRIPT_SOURCE="${DIR}/init_restore.sh"

# path (in live image, i.e. where to put the file for resizing
RECOVERY_SCRIPT_TARGET=/usr/lib/raspi-config/init_restore.sh

# this is used to fix/debug the resize script
RESIZE_SCRIPT_SOURCE="${DIR}/init_resize.sh"
RESIZE_SCRIPT_TARGET=/usr/lib/raspi-config/init_resize.sh

MOTD_SHOW_LIVE=""
SET_PI_PASSWORD=""
MSG_CONTINUE="...press enter to continue"
SECTOR_BYTES=512

OPTION_DO_RESIZE=1

SECTOR_SIZE=512

VERBOSITY=2