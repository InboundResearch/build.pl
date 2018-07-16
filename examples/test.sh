#! /usr/bin/env bash

# exit automatically if anything fails
set -e;

pushd simple;

build clean;
build;
build build;
target/simple/debug/simple;
build clean release run;
build clean;
#build TEST;

popd;

pushd complex;

# clean build, everything
build clean;
build;
build build;
build clean;
build;
LD_LIBRARY_PATH=target/test/debug:$LD_LIBRARY_PATH;
target/test/debug/test;
build clean common;
build clean release run;
build TEST;
build clean;

popd;

echo "PASS!";
