#!/usr/bin/env bash
#
# Bash script to install GMT dependencies on macOS via Homebrew
#
# Environmental variables that can control the installation:
#
set -x -e

# set defaults to false
BUILD_DOCS="${BUILD_DOCS:-false}"
RUN_TESTS="${RUN_TESTS:-false}"
PACKAGE="${PACKAGE:-false}"

# packages for compiling GMT
# cmake is pre-installed on GitHub Actions
packages="ninja curl pcre2 netcdf gdal geos fftw ghostscript"

if [ "$PACKAGE" = "true" ]; then
    # we need the GNU tar for packaging
    packages+=" gnu-tar"
fi

# Install GMT dependencies
#brew update
brew install ${packages}

set +x +e
