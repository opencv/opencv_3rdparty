#!/bin/bash -e

IPPICV_DATE=${1:?IPPICV date is not passed via argument}

files=($(shopt -s nullglob;shopt -s dotglob;echo downloads/ippicv*))
if [[ ${#files[@]} != 6 ]]; then
  echo "ERROR: Please put IPPICV files (for Windows/Mac/Linux platforms) into the downloads directory first."
  echo "       Found ${#files[@]} files (expected 6)"
  exit 1
fi

if ! git diff-index --quiet HEAD --; then
  echo "You have uncommited changes. Please commit your changes first"
  exit 1
fi

echo "### Update IPPICV binaries..."
(
  cp downloads/ippicv* ippicv/
)
echo "### Update IPPICV binaries... DONE"

DATE=`date +%Y%m%d`
BRANCH=`git rev-parse --abbrev-ref HEAD`
TARGET_BRANCH="${BRANCH}_${IPPICV_DATE}"

echo "### Commit IPPICV binaries to branch ${TARGET_BRANCH}..."
(
  git add ippicv/*
  git checkout -B ${TARGET_BRANCH}
  git commit -m "Update IPPICV binaries (${IPPICV_DATE})"
)
echo "### Commit IPPICV binaries to branch ${TARGET_BRANCH}... DONE"

echo ""
echo "1) Create pull request to OpenCV 3rdparty binaries repository with branch ${TARGET_BRANCH}"
echo "2) Create pull request to OpenCV repository:"
echo "   with updated names and hashes in <opencv>/3rdparty/ippicv/downloader.cmake:"
echo ""
echo "# Binary branch name: ${TARGET_BRANCH}"
echo "# Binaries were created for OpenCV: ${OPENCV_HASH}"
HASH=`git rev-parse HEAD`
echo "set(IPPICV_BINARIES_COMMIT \"${HASH}\")"
for f in ippicv/ippicv*; do
  HASH_BIN=($(md5sum $f))
  echo "# File \"$(basename $f)\" md5 hash: ${HASH_BIN}"
done
echo ""

echo "Checkout to branch with scripts only: ${BRANCH} ..."
git checkout ${BRANCH}
echo "All is OK"
