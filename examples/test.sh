#! /usr/bin/env bash

# exit automatically if anything fails
set -e;

echo "SIMPLE";
pushd simple > /dev/null;

echo "1";
build -clean;

echo "2";
build;

echo "3";
build -build;

echo "4";
target/simple/debug/simple;

echo "5";
build -clean release -run;

echo "6";
build -clean;
#build TEST;

popd > /dev/null;

echo "SIMPLE-WITH-TEST";
pushd simple-with-test > /dev/null;

echo "1";
build -clean;

echo "2";
build;

echo "3";
build -build simple;

echo "4";
target/simple/debug/simple;

echo "5";
build -clean release -run;

echo "6";
build -clean;

popd > /dev/null;

echo "COMPLEX";
pushd complex > /dev/null;

# clean build, everything
echo "1";
build -clean;

echo "1";
build;

echo "2";
build -build;

echo "3";
build -clean;

echo "4";
build;

echo "5";
export LD_LIBRARY_PATH=target/test/debug:$LD_LIBRARY_PATH;
target/test/debug/test;

echo "6";
build -clean common;

echo "7";
build -clean release -run;

echo "8";
build -clean;

popd > /dev/null;

echo "PASS!";
