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
update ffmpeg git://source.ffmpeg.org/ffmpeg.git n4.2.3
update openh264 https://github.com/cisco/openh264.git v1.8.0
update libvpx https://chromium.googlesource.com/webm/libvpx.git v1.8.2
)

# Pack all source code / build scripts
./archive_src.sh

echo "Downloading sources: DONE"
exit 0
