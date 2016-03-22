#!/bin/bash -ex
#
# This scripts creates build directory with:
# - ffmpeg: source tree, with fetched tag: n2.7.1 (git://source.ffmpeg.org/ffmpeg.git)
# - openh264: source tree, with fetched tag: v1.4.0 (https://github.com/cisco/openh264.git)
#
mkdir -p ../build
cd ../build
git clone git://source.ffmpeg.org/ffmpeg.git
(cd ffmpeg; git checkout n3.0)
git clone https://github.com/cisco/openh264.git
(cd openh264; git checkout v1.4.0)
