#!/bin/bash -ex
#
# This scripts creates build directory with:
# - ffmpeg source tree (git://source.ffmpeg.org/ffmpeg.git)
# - openh264 source tree (https://github.com/cisco/openh264.git)
# - libvpx source tree (https://chromium.googlesource.com/webm/libvpx.git)

update() {
  DIR=$1
  URL=$2
  TAG=$3
  [[ -d $DIR ]] || git clone $URL $DIR
  (
    cd $DIR
    git fetch -t $URL $TAG
    git checkout $TAG
  ) || exit 1
}

mkdir -p ../build
(
cd ../build
update ffmpeg git://source.ffmpeg.org/ffmpeg.git n3.3.2
update openh264 https://github.com/cisco/openh264.git v1.6.0
update libvpx https://chromium.googlesource.com/webm/libvpx.git v1.6.1
)
