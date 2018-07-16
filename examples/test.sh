#! /usr/bin/env bash

# exit automatically if anything fails
set -e;

pushd simple > /dev/null;

build clean;
build;
build build;
target/simple/debug/simple;
build clean release run;
build clean;
#build TEST;

popd > /dev/null;

pushd simple-with-test > /dev/null;

build clean;
build;
build build simple;
target/simple/debug/simple;
build clean release run;
build clean;
build TEST;

popd > /dev/null;

pushd complex > /dev/null;

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

popd > /dev/null;

echo "PASS!";
