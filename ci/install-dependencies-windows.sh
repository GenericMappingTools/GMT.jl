#!/usr/bin/env bash
#
# Bash script to install GMT dependencies on Windows via vcpkg and chocolatey
#
# Environmental variables that can control the installation:
#
# - BUILD_DOCS: Build GMT documentation  [false]
# - RUN_TESTS:  Run GMT tests            [false]
# - PACKAGE:    Create GMT packages      [false]
#

set -x -e

# set defaults to false
BUILD_DOCS="${BUILD_DOCS:-false}"
RUN_TESTS="${RUN_TESTS:-false}"
PACKAGE="${PACKAGE:-false}"

WIN_PLATFORM=x64-windows

# install libraries
choco install ghostscript wget ninja
wget http://fct-gmt.ualg.pt/gmt/data/wininstallers/gmt-win64.exe
cmd /k gmt-win64.exe /S


if [ "$BUILD_DOCS" = "true" ]; then
    pip install --user sphinx dvc
    # Add sphinx to PATH
    echo "$(python -m site --user-site)\..\Scripts" >> $GITHUB_PATH

    # choco install pngquant
fi

if [ "$RUN_TESTS" = "true" ]; then
    choco install graphicsmagick --version 1.3.32
    pip install --user dvc
    # Add GraphicsMagick to PATH
    echo 'C:\Program Files\GraphicsMagick-1.3.32-Q8' >> $GITHUB_PATH
    # Add dvc to PATH
    echo "$(python -m site --user-site)\..\Scripts" >> $GITHUB_PATH
fi

# we need the GNU tar for packaging
if [ "$PACKAGE" = "true" ]; then
    echo 'C:\Program Files\Git\usr\bin\' >> $GITHUB_PATH
fi

set +x +e
