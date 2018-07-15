#! /usr/bin/env bash

pushd one
# clean build, everything
rm -rf target
build.pl target=* configuration=*

# do it again to be sure no work needs to be done
build.pl "$@" target=* configuration=*

# clean default build, and run the test
rm -rf target
build.pl
one/target/test/debug/test

# clean build debug common
rm -rf target
build.pl target=common

# clean build default target release
rm -rf target
build.pl "$@" configuration=release

# clean build
rm -rf target

popd

pushd two

# clean build, everything
rm -rf target
build.pl target=* configuration=*

build.sh clean

build.sh

build.sh release run

build.sh clean

popd

