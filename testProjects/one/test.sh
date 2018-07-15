#! /usr/bin/env bash

# clean build, everything
rm -rf target
../bin/build.pl target=* configuration=*

# do it again to be sure no work needs to be done
../bin/build.pl "$@" target=* configuration=*

# clean default build, and run the test
rm -rf target
../bin/build.pl
target/test/debug/test

# clean build debug common
rm -rf target
../bin/build.pl target=common

# clean build default target release
rm -rf target
../bin/build.pl "$@" configuration=release

# clean build
rm -rf target

