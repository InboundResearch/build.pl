#!/usr/bin/env bash

# basic "make" replacement using build.pl behind the scenes to do the build - this is not intended
# to be a comprehensive make replacement, just a helper script to add a few other capabilities that
# build.pl doesn't cover

# exit automatically if anything fails
set -e

UNKNOWN="UNKNOWN";
shouldClean=0;
shouldBuild=0;
shouldRun=0;
shouldConfiguration="debug";
sourceDir=$(getcontextvars.pl sourcePath);

# the default target is "test", but if it's not present, find the first available project
if [ -d "$sourceDir/test" ]; then
    # test if it exists
    shouldTarget="test";
else
    projects=($(getcontextvars.pl projects));
    if [ ${#projects[@]} -gt "0" ]; then
        shouldTarget="${projects[0]}";
        #echo "TARGET=$shouldTarget";
    else
        shouldTarget="$UNKNOWN";
    fi
fi

if [ "$#" -gt 0 ]; then
    for target in "$@"; do
        #echo $COMMAND;
        case "${target}" in
            clean)
                shouldClean=1;
                ;;
            build)
                shouldBuild=1;
                ;;
            run)
                shouldRun=1;
                ;;
            debug)
                shouldConfiguration="debug";
                shouldBuild=1;
                ;;
            release)
                shouldConfiguration="release";
                shouldBuild=1;
                ;;
            all)
                shouldBuild=1;
                shouldRun=0;
                shouldTarget="*";
                shouldConfiguration="*";
                ;;
            TEST)
                # a special target for "clean build debug test run"
                if [ -d "$sourceDir/test" ]; then
                    shouldClean=1;
                    shouldBuild=1;
                    shouldRun=1;
                    shouldTarget="test";
                    shouldConfiguration="debug";
                else
                    echo "Unknown target (test)";
                    exit 1;
                fi
                ;;
            *)
                if [ -d "$sourceDir/$target" ]; then
                    shouldBuild=1;
                    shouldTarget="$target";
                else
                    echo "Unknown target ($target)";
                    exit 1;
                fi
                ;;
        esac
    done
else
    # default to build and run in debug mode (no clean)
    shouldBuild=1;
    shouldRun=1;
fi

if [ "$shouldClean" -eq 1 ]; then
    echo "clean";
    rm -rf target;
fi

if [ "$shouldTarget" != "$UNKNOWN" ]; then
    if [ "$shouldBuild" -eq 1 ] || [ "$shouldRun" -eq 1 ]; then
        build.pl target="$shouldTarget" configuration="$shouldConfiguration";
    fi

    if [ "$shouldRun" -eq 1 ]; then
        # linux might need to set some link loader libraries
        target/$shouldTarget/$shouldConfiguration/$shouldTarget;
    fi
else
    if [ "$shouldBuild" -eq 1 ] || [ "$shouldRun" -eq 1 ]; then
        echo "No target specified";
        exit 1;
    fi
fi
