#!/usr/bin/env bash
set -ex

# build system uses non-standard env vars
uname=$(uname)
if [[ "$target_platform" == osx* ]]; then
  #export LIBS="${LIBS} -L${PREFIX}/lib -v"
  #export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -v"
  export CFLAGS="${CFLAGS} -I ${PREFIX}/include/freetype2"
  export CFLAGS="${CFLAGS} -I $(ls -d ${PREFIX}/include/openjpeg-*)"
  export CFLAGS="${CFLAGS} -Wno-incompatible-function-pointer-types"
  #export SYS_FREETYPE_LIBS=" -lfreetype"
  #export SYS_FREETYPE_CFLAGS="${CFLAGS}"
  export TESSERACT=false
else
  export TESSERACT=yes
fi
if [[ "$target_platform" == osx-arm64 ]]; then
  export ARCHFLAGS="-arch arm64"
fi
export CFLAGS="${CFLAGS} -I ${PREFIX}/include/harfbuzz"
export XCFLAGS="${CFLAGS}"
export XLIBS="${LIBS}"
export USE_SYSTEM_LIBS=yes
export USE_SYSTEM_JPEGXR=yes
export VENV_FLAG=""

# Point the mupdf Python binding build to the HOST Python (not BUILD_PREFIX Python).
# Without this, pipcl.PythonFlags uses sys.executable (BUILD_PREFIX Python 3.14)
# to find python-config, causing an ABI mismatch with the target Python 3.13.
export PIPCL_PYTHON_CONFIG="${PREFIX}/bin/python3-config"

# diagnostics
#ls -lh ${PREFIX}/lib

# build and install
# Build 'all' and 'python' targets separately to avoid a race condition:
# 'python' depends on 'shared-release' which triggers a recursive make that
# races with the parent make's link step for mutool (undefined murun_main).
make prefix="${PREFIX}" pydir="${SP_DIR}" tesseract=${TESSERACT} shared=yes -j ${CPU_COUNT} all
make prefix="${PREFIX}" pydir="${SP_DIR}" tesseract=${TESSERACT} shared=yes -j ${CPU_COUNT} python

# no make check
make prefix="${PREFIX}" pydir="${SP_DIR}" tesseract=${TESSERACT} shared=yes install install-shared-python
