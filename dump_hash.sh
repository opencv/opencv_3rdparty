#!/bin/bash -e

dump_md5() {
  FILE=$1
  FILE_ID=$2
  FILE_HASH=($(md5sum $1))
  echo "set(FILE_HASH_${FILE_ID} \"${FILE_HASH}\")"
}

echo ""
echo "1) Create pull request to OpenCV 3rdparty binaries repository"
echo "2) Create pull request to OpenCV contrib repository:"
echo "   with updated hashes in <opencv_contrib>/modules/xfeatures2d/cmake/download_vgg.cmake:"

HASH=`git rev-parse HEAD`
echo ""
echo "set(OPENCV_3RDPARTY_COMMIT \"${HASH}\")"
dump_md5 vgg_generated_48.i VGG_48
dump_md5 vgg_generated_64.i VGG_64
dump_md5 vgg_generated_80.i VGG_80
dump_md5 vgg_generated_120.i VGG_120
echo ""
