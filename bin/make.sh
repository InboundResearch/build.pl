#!/usr/bin/env bash

# basic "make" replacement using build.pl behind the scenes to do the build - this is not intended
# to be a comprehensive make replacement, just a helper script to add a few other capabilities that
# build.pl doesn't cover
set -e

UNKNOWN="UNKNOWN";
shouldClean=0;
shouldBuild=0;
shouldRun=0;
shouldTarget="$UNKNOWN";
shouldConfiguration="debug";

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
                ;;
            release)
                shouldConfiguration="release";
                ;;
            TEST)
                # a special target for "clean build debug test run"
                if [ -d "source/test" ]; then
                    shouldClean=1;
                    shouldBuild=1;
                    shouldRun=1;
                    shouldTarget="test";
                    shouldConfiguration="debug";
                else
                    echo "Unknown target (test)";
                fi
                ;;
            *)
                if [ -d "source/$target" ]; then
                    shouldBuild=1;
                    shouldTarget="$target";
                else
                    echo "Unknown target ($target)";
                fi
                ;;
        esac
    done
else
    # default to build and run test in debug mode (no clean)
    if [ -d "source/test" ]; then
        shouldConfiguration="debug";
        shouldTarget="test";
        shouldBuild=1;
        shouldRun=1;
    fi
fi

if [ "$shouldClean" -eq 1 ]; then
    echo "clean";
    rm -rf target;
fi

if [ "$shouldTarget" != "$UNKNOWN" ]; then
    if [ "$shouldBuild" -eq 1 ]; then
        build.pl target="$shouldTarget" configuration="$shouldConfiguration";
    fi

    if [ "$shouldRun" -eq 1 ]; then
        # linux might need to set some link loader libraries
        target/$shouldTarget/$shouldConfiguration/$shouldTarget;
    fi
else
    if [ "$shouldBuild" -eq 1 ] || [ "$shouldRun" -eq 1 ]; then
        echo "no target specified";
    fi
fi
