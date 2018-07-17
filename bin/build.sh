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
shouldConfiguration=$(getcontextvars.pl configuration);
sourceDir=$(getcontextvars.pl sourcePath);
targetDir=$(getcontextvars.pl buildPath);
defaultTarget=$(getcontextvars.pl target);
shouldTarget="";
allTargets=($(getcontextvars.pl projects));
targetSeparator="";

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
                shouldTarget=$allTargets;
                ;;
            *)
                if [ -d "$sourceDir/$target" ]; then
                    shouldBuild=1;
                    shouldTarget="$shouldTarget$targetSeparator$target";
                    targetSeparator=",";
                else
                    echo "Unknown target ($target)";
                    exit 1;
                fi
                ;;
        esac
    done
else
    # default to build and run in the default configuration (no clean)
    shouldBuild=1;
    shouldRun=1;
fi

# a little bit of massaging on the default targets
if [ "$shouldTarget" == "" ]; then
    shouldTarget=$defaultTarget;
fi
if [ "$shouldTarget" == "*" ]; then
    shouldTarget=$allTargets;
fi

# debug points
#echo "shouldClean=$shouldClean";
#echo "shouldBuild=$shouldBuild";
#echo "shouldRun=$shouldRun";
#echo "shouldConfiguration=$shouldConfiguration";
#echo "sourceDir=$sourceDir";
#echo "targetDir=$targetDir";
#echo "shouldTarget=$shouldTarget";

if [ "$shouldClean" -eq 1 ]; then
    echo "clean";
    rm -rf $targetDir;
fi

if [ "$shouldTarget" != "" ]; then
    if [ "$shouldBuild" -eq 1 ] || [ "$shouldRun" -eq 1 ]; then
        # little sanity check - do the targets have source files?
        IFS="," read -r -a targets <<< "$shouldTarget";
        target="${targets[0]}";
        sourceExtension=$(getcontextvars.pl sourceExtension);
        sourceCount=$(ls -1 "$sourceDir/$target" 2> /dev/null | grep "$sourceExtension" | wc -l);
        if [ "$sourceCount" -gt 0 ]; then
            build.pl target="$shouldTarget" configuration="$shouldConfiguration";
        else
            echo "No sources in $target, is this a project?";
            exit 1;
        fi
    fi

    if [ "$shouldRun" -eq 1 ]; then
        IFS="," read -r -a targets <<< "$shouldTarget";
        for target in "${targets[@]}"; do
            if [ -x "$targetDir/$target/$shouldConfiguration/$target" ]; then
                echo;
                # linux needs to set the shared library path
                export LD_LIBRARY_PATH=$targetDir/$target/$shouldConfiguration:$LD_LIBRARY_PATH;
                $targetDir/$target/$shouldConfiguration/$target 2> >(tee $targetDir/$target/$shouldConfiguration/$target.stderr) ;
            fi
        done
    fi
else
    echo "No target specified";
    exit 1;
fi

exit 0;
