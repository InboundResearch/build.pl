#!/usr/bin/env bash

# basic "make" replacement using build.pl behind the scenes to do the build - this is not intended
# to be a comprehensive make replacement, just a helper script to add a few other capabilities that
# build.pl doesn't cover

# exit automatically if anything fails
set -e

# the default build.pl configuration will look for targets in the current directory, or a build.json
# file that specifies where the targets are. occasionally, users will "accidentally" run from within
# the project, but it might look like it is the project level. we look up a little bit to see if we
# find a build.json to prevent some of the problems that might cause - worst case - search up to the
# user's home directory (~), or the root, but take the highest one we find...
searchDir=".";
projectDir=".";
stopDir=$(cd ~; echo $PWD;);
rootDir=$(cd /; echo $PWD;);
while [ "$(cd $searchDir; echo $PWD;)" != "$stopDir" ] && [ "$(cd $searchDir; echo $PWD;)" != "$rootDir" ]; do
    #echo "$(cd $searchDir; echo $PWD;)";
    if [ -f "$searchDir/build.json" ]; then
        projectDir="$searchDir";
        #echo "FOUND $(cd $searchDir; echo $PWD;)";
    fi
    searchDir="../$searchDir";
done
cd "$projectDir";
echo "PROJECT: $PWD";

# all the values we will use to do the actual build, with default values pre-populated with
# reasonable defaults.
shouldClean=0;
shouldBuild=0;
shouldRun=0;
shouldConfiguration=$(getcontextvars.pl configuration);
sourceDir=$(getcontextvars.pl sourcePath);
targetDir=$(getcontextvars.pl buildPath);
defaultTarget=$(getcontextvars.pl target);
shouldTarget="";
allTargets=($(getcontextvars.pl targets));
allConfigurations=($(getcontextvars.pl configurations));
targetSeparator="";

# process the command line options. these cover a range of expected options (clean, build, run),
# the ability to specify one or more values that match a target or configuration (which are not
# known a-priori and so are not hard-coded into the options), and the special value (all), which
# builds all the targets.
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
            all)
                shouldBuild=1;
                shouldTarget=$allTargets;
                ;;
            *)
                # non-hard-coded command-line options are checked to see if they are a valid target
                if [ -d "$sourceDir/$target" ]; then
                    # ensure that we will build, then add the target to the shouldTarget list. the
                    # separator is set so that subsequent targets get added to the list as a comma
                    # separated list.
                    shouldBuild=1;
                    echo "TARGET: $target";
                    shouldTarget="$shouldTarget$targetSeparator$target";
                    targetSeparator=",";
                else
                    # check against available configurations?
                    matchedConfiguration=0;
                    IFS="," read -r -a configurations <<< "$allConfigurations";
                    for configuration in "${configurations[@]}"; do
                        if [ "$target" == "$configuration" ]; then
                            echo "CONFIGURATION: $configuration";
                            shouldConfiguration=$target;
                            matchedConfiguration=1;
                        fi
                    done

                    # check if we matched a valid configuration
                    if [ "$matchedConfiguration" -eq 0 ]; then
                        # don't try to figure out what the user meant, just die...
                        echo "Unknown target ($target)";
                        exit 1;
                    fi
                fi
                ;;
        esac
    done
else
    # default to build and run in the default configuration (no clean)
    shouldBuild=1;
    shouldRun=1;
fi

# a little bit of massaging on the default targets, so that if the user didn't supply a target, we
# can fill in the defaults from the global default context and/or local project context
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

# if clean was requested, do that now...
if [ "$shouldClean" -eq 1 ]; then
    echo "clean";
    rm -rf $targetDir;
fi

# after everything, if there is a build/run target...
if [ "$shouldTarget" != "" ]; then
    # if build or run was requested, do that now...
    if [ "$shouldBuild" -eq 1 ] || [ "$shouldRun" -eq 1 ]; then
        # a little sanity check - check that all the targets have source files
        IFS="," read -r -a targets <<< "$shouldTarget";
        sourceExtension=$(getcontextvars.pl sourceExtension);
        for target in "${targets[@]}"; do
            sourceCount=$(ls -1 "$sourceDir/$target" 2> /dev/null | grep "$sourceExtension" | wc -l);
            if [ "$sourceCount" -eq 0 ]; then
                echo "No sources in $target, is this a project?";
                exit 1;
            fi
        done

        # all the targets have source files... let's build using build.pl
        #echo "BUILD.PL IS BEING RUN ON: $shouldTarget";
        build.pl target="$shouldTarget" configuration="$shouldConfiguration";
    fi

    # if run was requested, do that now...
    if [ "$shouldRun" -eq 1 ]; then
        # linux and MacOS need to set the shared library path, we capture it like this so that we
        # don't make a really long load path when we are running multiple programs in sequence
        oldLibPath=$LD_LIBRARY_PATH;
        oldDyLibPath=$DYLD_LIBRARY_PATH;

        # break the targets out into an array (it's a comma delimited string), and loop over them
        # one by one
        IFS="," read -r -a targets <<< "$shouldTarget";
        for target in "${targets[@]}"; do
            # build a target path, then check to see if there is an executable
            targetPath="$targetDir/$target/$shouldConfiguration";
            if [ -x "$targetPath/$target" ]; then
                echo "RUN: $targetPath/$target";
                # go into the target directory - this makes the working directory the same as the
                # executable directory, which simplifies some testing
                pushd "$targetPath" > /dev/null;

                # set the shared library search path to include the full path of the working dir
                export LD_LIBRARY_PATH="$PWD:$oldLibPath";
                export DYLD_LIBRARY_PATH="$PWD:$oldDyLibPath";

                # we run the target, but we have to give it a path, because some built executables
                # might look like system or shell commands without it (i.e. test)
                echo;
                ./$target 2> >(tee $target.stderr);
                echo;

                # and go back to where we were...
                popd > /dev/null;
            fi
        done
    fi
else
    echo "No target specified";
    exit 1;
fi

echo "FINISHED.";

exit 0;
