#!/bin/bash -ex

rm -rf ../sources
mkdir -p ../sources
mkdir -p ../sources/opencv
mkdir -p ../sources/build/ffmpeg
mkdir -p ../sources/build/libvpx
mkdir -p ../sources/build/openh264

ARCHIVE_TYPE=tar.xz
(
cd ..
git archive --format=tar HEAD | xz -c - > sources/opencv_ffmpeg.${ARCHIVE_TYPE}
)
(
cd ../opencv
git archive --format=tar HEAD modules/videoio/src/*ffmpeg*.hpp LICENSE | xz -c - > ../sources/opencv/opencv-videoio-ffmpeg.${ARCHIVE_TYPE}
)
(
cd ../build/ffmpeg
git archive --format=tar HEAD | xz -c - > ../../sources/build/ffmpeg/ffmpeg-src-$(git describe --tags).${ARCHIVE_TYPE}
)
(
# We use headers for public API only
cd ../build/openh264
git archive --format=tar HEAD codec/api/svc LICENSE | xz -c - > ../../sources/build/openh264/openh264-api-headers-$(git describe --tags).${ARCHIVE_TYPE}
)
(
cd ../build/libvpx
git archive --format=tar HEAD | xz -c - > ../../sources/build/libvpx/libvpx-src-$(git describe --tags).${ARCHIVE_TYPE}
)

find ../sources/

echo "Archiving sources: DONE"
exit 0
