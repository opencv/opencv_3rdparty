#!/bin/bash -e

if ! git diff-index --quiet HEAD --; then
  echo "You have uncommited changes. Please commit your changes first"
  exit 1
fi

echo "### Update code from OpenCV repository..."
[[ "${BUILD_SKIP_OPENCV_UPDATE}" == "" ]] &&
(
  cd opencv
  git fetch https://github.com/Itseez/opencv.git master
  if [[ `git merge-base HEAD FETCH_HEAD` != `git rev-parse HEAD` ]]; then
    echo "OpenCV folder contains changes. Please save your changes and checkout the latest code: $(pwd)"
    exit 1
  fi
  if ! git diff-index --quiet HEAD --; then
    echo "OpenCV folder contains unsaved changes. Please save (stash) your changes and checkout the latest code: $(pwd)"
    exit 1
  fi
  git checkout -B ffmpeg_update FETCH_HEAD
)
OPENCV_HASH=`cd opencv; git rev-parse HEAD`
echo "### Update code from OpenCV repository... DONE (${OPENCV_HASH})"

if ! git diff-index --quiet HEAD --; then
  echo "### OpenCV git submodule is updated. Will commit this update..."
  git commit -am "update OpenCV code"
  echo "### ... DONE"
fi

echo "### Build ffmpeg wrapper binaries..."
(
  ./ffmpeg/build_via_docker.sh
)
echo "### Build ffmpeg wrapper binaries... DONE"

DATE=`date +%Y%m%d`
BRANCH=`git rev-parse --abbrev-ref HEAD`
TARGET_BRANCH="${BRANCH}_${DATE}"

echo "### Commit ffmpeg wrapper binaries to branch ${TARGET_BRANCH}..."
(
  git add ffmpeg/opencv_ffmpeg.dll
  git add ffmpeg/opencv_ffmpeg_64.dll
  git checkout -B ${TARGET_BRANCH}
  git commit -m "Update ffmpeg binaries (${DATE}-${OPENCV_HASH})"
)
echo "### Commit ffmpeg wrapper binaries to branch ${TARGET_BRANCH}... DONE"

echo ""
echo "1) Create pull request to OpenCV 3rdparty binaries repository with branch ${TARGET_BRANCH}"
echo "2) Create pull request to OpenCV repository:"
echo "   with updated hashes in <opencv>/3rdparty/ffmpeg/ffmpeg.cmake:"
HASH=`git rev-parse HEAD`
HASH_BIN32=($(md5sum ffmpeg/opencv_ffmpeg.dll))
HASH_BIN64=($(md5sum ffmpeg/opencv_ffmpeg_64.dll))
HASH_CMAKE=($(md5sum ffmpeg/ffmpeg_version.cmake))
echo ""
echo "# Binary branch name: ${TARGET_BRANCH}"
echo "# Binaries were created for OpenCV: ${OPENCV_HASH}"
echo "set(FFMPEG_BINARIES_COMMIT \"${HASH}\")"
echo "set(FFMPEG_FILE_HASH_BIN32 \"${HASH_BIN32}\")"
echo "set(FFMPEG_FILE_HASH_BIN64 \"${HASH_BIN64}\")"
echo "set(FFMPEG_FILE_HASH_CMAKE \"${HASH_CMAKE}\")"
echo ""

echo "Checkout to branch with scripts only: ${BRANCH} ..."
git checkout ${BRANCH}
echo "All is OK"
