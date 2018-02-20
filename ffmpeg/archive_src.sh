#!/bin/bash -x

rm -rf ../sources
mkdir -p ../sources
mkdir -p ../sources/opencv
mkdir -p ../sources/build

ARCHIVE_TYPE=tar.xz
(
cd ..
git archive --format=tar HEAD | xz -c - > sources/opencv_ffmpeg.${ARCHIVE_TYPE}
)
(
cd ../opencv
git archive --format=tar HEAD modules/videoio/src/*ffmpeg* | xz -c - > ../sources/opencv/opencv_videoio.${ARCHIVE_TYPE}
)
(
cd ../build/ffmpeg
git archive --format=tar --prefix=ffmpeg/ HEAD | xz -c - > ../../sources/build/ffmpeg.${ARCHIVE_TYPE}
)
(
# We use headers for public API only
cd ../build/openh264
git archive --format=tar --prefix=openh264/ HEAD codec/api/svc | xz -c - > ../../sources/build/openh264.${ARCHIVE_TYPE}
)
(
cd ../build/libvpx
git archive --format=tar --prefix=libvpx/ HEAD | xz -c - > ../../sources/build/libvpx.${ARCHIVE_TYPE}
)
