

# DEFAULT_BASE=2018-03-13-raspbian-stretch-lite
# DEFAULT_BASE=2018-06-27-raspbian-stretch-lite
# DEFAULT_BASE=2018-10-09-raspbian-stretch-lite
DEFAULT_BASE=2021-01-11-raspios-buster-armhf-lite

BASE=${OPTION_BASE:-$DEFAULT_BASE}

# if the BASE has a suffix, remove it

BASE=${BASE%.img}

echo $BASE

# get current source dir, even if its hidden in links
# needed for full paths relative to this script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

echo "base DIR is ${DIR}"

# paths for base, intermediate and restore images
# this isn't touched
IMG_ORIG="${DIR}/${BASE}.img"


# this is the ultimate output image that should be used for flashing
IMG_RESTORE="${DIR}/${BASE}.restore.img"

# this is for intermediate modifications before writing out
IMG_LIVE="${DIR}/${BASE}.live.img"

# paths to script that is used for resetting in live image
RECOVERY_SCRIPT_SOURCE="${DIR}/init_restore.sh"

# path (in live image, i.e. where to put the file for resizing
RECOVERY_SCRIPT_TARGET=/usr/lib/raspi-config/init_restore.sh

# this is used to fix/debug the resize script
RESIZE_SCRIPT_SOURCE="${DIR}/init_resize.sh"
RESIZE_SCRIPT_TARGET=/usr/lib/raspi-config/init_resize.sh

MOTD_SHOW_LIVE=""
SET_PI_PASSWORD=""
