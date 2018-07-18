#! /usr/bin/env perl

use strict;
use warnings FATAL => 'all';
#use diagnostics;

# utf8 everything...
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use utf8;

# we will use multiple threads to compile the files
use threads;

use File::Copy;
use File::Path qw(make_path);
use File::Basename;
use Cwd qw(abs_path);

# search under the script directory location for the "my" libs
use lib dirname (abs_path(__FILE__)) . "/my";
use Context qw(%ContextType);
use Slurp qw(slurp);

#---------------------------------------------------------------------------------------------------
# phase 1 - get the contexts
#---------------------------------------------------------------------------------------------------
# root and project contexts
Context::load ("root", dirname(abs_path(__FILE__)));
Context::load ("project", ".");

# process the command line options into a context and store it
# XXX TODO: figure out a way to do a sanity check on variables entered
my $commandLineContext = {};
foreach my $argument (@ARGV) {
    if ($argument =~ /^([^=]*)=([^=]*)$/) {
        print STDERR "$1 = $2\n";
        $commandLineContext->{$1} = $2;
    }
}
Context::addTypeNamed("commandline", $ContextType{VALUES}, $commandLineContext);

# put them all together and replace the project-values context
Context::addTypeNamed("project", $ContextType{VALUES},
    Context::concatenateNamed (
        "root-" . $ContextType{VALUES},
        "project-" . $ContextType{VALUES},
        "commandline-" . $ContextType{VALUES}
    )
);

#---------------------------------------------------------------------------------------------------
# phase 2 - read the source path looking for subdirs, and loading their contexts
#---------------------------------------------------------------------------------------------------
my $targets = {};
my $targetPrefix = "#";
my $sourcePath = Context::confType ("project", $ContextType{VALUES}, "sourcePath");

if (opendir(SOURCE_PATH, $sourcePath)) {
    while (my $target = readdir(SOURCE_PATH)) {
        # skip unless $target is a non-hidden directory, that is not also the build directory
        next unless (($target !~ /^\./) && (-d "$sourcePath/$target"));
        next if (abs_path("$sourcePath/$target") eq abs_path(Context::confType ("project", $ContextType{VALUES}, "buildPath")));

        # load the target context to get the dependencies
        Context::load ("$targetPrefix$target", "$sourcePath/$target/");
        my $targetContext = Context::concatenateNamed ("project-" . $ContextType{VALUES}, "$targetPrefix$target-" . $ContextType{VALUES});
        $targets->{$target} = $targetContext;
    }
    closedir(SOURCE_PATH);
} else {
    print STDERR "Can't open source directory ($sourcePath), $!\n";
    exit ($!);
}

#---------------------------------------------------------------------------------------------------
# phase 3 - identify the targets to build, and the dependency order to do it
#---------------------------------------------------------------------------------------------------
# the dependency graph is implicit in the dependencies array for each target, so we traverse it in
# depth first order, emitting build targets on return (and marking them as "touched" so we don't
# emit them twice).
sub traverseTargetDependencies {
    my ($targetDependencies, $target, $forTarget) = @_;
    if (exists ($targets->{$target})) {
        if (!exists($targets->{$target}->{touched})) {
            $targets->{$target}->{touched} = 1;
            my $dependencies = exists($targets->{$target}->{dependencies}) ? $targets->{$target}->{dependencies} : [];
            for my $dependency (sort (@$dependencies)) {
                traverseTargetDependencies($targetDependencies, $dependency, $forTarget);
            }
            push (@$targetDependencies, $target);
        }
    } else {
        print STDERR "Dependency ($target) of ($forTarget) is not a known target.\n";
        exit (1);
    }
}

# traverse the dependencies for all the targets into one list
my $targetsToBuild = Context::confType ("project", $ContextType{VALUES}, "target");
$targetsToBuild = (ref $targetsToBuild eq "ARRAY") ? $targetsToBuild : (($targetsToBuild ne "*") ? [split (/[, ]+/, $targetsToBuild)] : [sort keys (%$targets)]);
my $targetsInDependencyOrder = [];
for my $target (@$targetsToBuild) {
    traverseTargetDependencies ($targetsInDependencyOrder, $target, $target);
}

#---------------------------------------------------------------------------------------------------
# phase 4 - walk the targets in dependency order to build
#---------------------------------------------------------------------------------------------------
sub readObjectDependencies {
    my ($sourceContext) = @_;
    my $dependencyFile = $sourceContext->{dependencyFile};
    my $dependencies = slurp ($dependencyFile) || $sourceContext->{sourceFile};
    $dependencies = ((($dependencies =~ s/\\//gr) =~ s/\s+/ /gr) =~ s/.*: +//gr);
    return [split (/ /, $dependencies)];
}

sub checkObjectDependencies {
    my ($sourceContext) = @_;

    # if the object file exists, compare its age to the dependencies
    my $objectFile = $sourceContext->{objectFile};
    if (-e $objectFile) {
        my $objectAgeDelta = (-M $objectFile);
        my $dependencies = readObjectDependencies ($sourceContext);
        for my $dependency (@$dependencies) {
            if ((-M $dependency) < $objectAgeDelta) {
                # this dependency is younger than the object file, so the file should be rebuilt
                return 1;
            }
        }
        # none of the dependencies is younger than this file, so it does not need to be rebuilt
        return 0;
    } else {
        # the object doesn't exist, it should be built
        return 1;
    }
}

#---------------------------------------------------------------------------------------------------
sub getTargetDependencies {
    my ($target, $dependencies)  = @_;

    # set all the existing dependencies to untouched
    for my $key (keys (%$targets)) {
        delete $targets->{$key}->{touched};
    }

    # traverse the dependency graph for this target
    my $targetDependencies = [];
    for my $dependency (@$dependencies) {
        traverseTargetDependencies($targetDependencies, $dependency, $target);
    }
    return $targetDependencies;
}

#---------------------------------------------------------------------------------------------------
for my $target (@$targetsInDependencyOrder) {
    # determine what configurations are available vs. what was requested, and loop over the
    # intersection of those two sets
    my $configurations = Context::concatenate (
        Context::getTypeNamed("root", $ContextType{CONFIGURATIONS}),
        Context::getTypeNamed("project", $ContextType{CONFIGURATIONS}),
        Context::getTypeNamed("$targetPrefix$target", $ContextType{CONFIGURATIONS})
    );

    my $configurationToBuild = $targets->{$target}->{configuration};
    $configurationToBuild = (ref $configurationToBuild eq "ARRAY") ? $configurationToBuild : (($configurationToBuild ne "*") ? [ split(/[, ]+/, $configurationToBuild) ] : [ sort keys (%$configurations) ]);
    for my $configuration (@$configurationToBuild) {
        if (exists ($configurations->{$configuration})) {
            print STDERR "BUILD $target/$configuration\n";

            # reload the target context, concatenate it with the correct configuration contexts, then
            # the type contexts
            Context::load("$targetPrefix$target", "$sourcePath/$target/");
            my $targetContext = Context::concatenateNamed(
                "project-" . $ContextType{VALUES},
                "$targetPrefix$target-" . $ContextType{VALUES}
            );
            $targetContext = Context::concatenate(
                $targetContext,
                { target => "$target", configuration => "$configuration" },
                Context::concatenate(
                    Context::getTypeNamed("root", $ContextType{CONFIGURATIONS})->{$configuration},
                    Context::getTypeNamed("project", $ContextType{CONFIGURATIONS})->{$configuration},
                    Context::getTypeNamed("$targetPrefix$target", $ContextType{CONFIGURATIONS})->{$configuration}
                ),
                Context::concatenate(
                    Context::getTypeNamed("root", $ContextType{TYPES})->{$targetContext->{type}},
                    Context::getTypeNamed("project", $ContextType{TYPES})->{$targetContext->{type}},
                    Context::getTypeNamed("$targetPrefix$target", $ContextType{TYPES})->{$targetContext->{type}}
                )
            );

            # a couple of passes at reduction
            # XXX TODO: this needs a bit more thought about how reduction works
            for (my $i = 0; $i < 3; $i++) {
                $targetContext = Context::reduce($targetContext);
            }

            # ensure the target directory is present
            make_path($targetContext->{objectsFullPath});

            # gather up the target dependencies for includes and linkages - if a dependency exists, it
            # should have already been fully built before we come to this project
            # XXX TODO: is that true - link dependencies only exist for apps, so it is - but one library
            # XXX TODO: could include headers from another (one presumes), and I can even see circular
            # XXX TODO: dependencies arising out of that...
            my $includes = "-I$sourcePath ";
            my $libraries = "";
            my $separator = "";
            my $dependencies = getTargetDependencies ($target, exists($targetContext->{dependencies}) ? $targetContext->{dependencies} : []);
            for my $dependency (@$dependencies) {
                $includes .= $separator . $targets->{$dependency}->{toInclude};
                $libraries .= $separator . $targets->{$dependency}->{linkTo};
                $separator = " ";
            }
            #print STDERR "    INCLUDES: $includes\n";
            #print STDERR "    LIBRARIES: $libraries\n";

            # and we manually integrate these values into the target context, because we know this step
            # has to happen, and there really isn't a way to hide it behind a config option
            $targetContext->{includes} = $includes;
            $targetContext->{libraries} = $libraries;
            $targetContext = Context::reduce($targetContext);

            # save the processed target context back to the targets array
            $targets->{$target} = $targetContext;

            # a little bit of setup for threading the compilations
            my @threads;

            # loop over all the source files in the source path to compile them, if needed
            # XXX TODO: should this load all the sources and process them in some order (alphabetical)?
            if (opendir(SOURCE_TARGET_DIR, $targetContext->{sourceFullPath})) {
                while (my $sourceTargetFile = readdir(SOURCE_TARGET_DIR)) {
                    if ($sourceTargetFile =~ /(.*)$targetContext->{"sourceExtension"}$/) {
                        my $sourceBaseContext = { sourceBase => "$1" };
                        my $sourceContext = Context::reduce(
                            Context::concatenate(
                                $targetContext,
                                $sourceBaseContext
                            )
                        );

                        # load the source dependency file and check if we need to rebuild it
                        if (checkObjectDependencies($sourceContext)) {
                            # spawn a thread here - a bit brutal, a new thread for every compilation
                            my ($thread) = threads->create( sub {
                                # compile the source file, and check if it succeeds
                                my $compile = $sourceContext->{compiler} . " " . $sourceContext->{compilerOptions};
                                print STDERR "    COMPILE: $compile\n";
                                my $result = system($compile);
                                if ($result == 0) {
                                    # update the dependencies... this should succeed if the compilation
                                    # did - but the output is directed to the dependency file, so we want to
                                    # remove that if it fails
                                    my $depend = $sourceContext->{depender} . " " . $sourceContext->{dependerOptions};
                                    if (system($depend) != 0) {
                                        print STDERR "    DEPEND FAILED: $depend\n";
                                        unlink($sourceContext->{dependencyFile});
                                    }
                                    return 1;
                                }
                                return 0;
                            });
                            push (@threads, $thread);
                        }
                    }
                }
                closedir(SOURCE_TARGET_DIR);
            }
            else {
                print STDERR "Can't open target source directory ($targetContext->{sourceFullPath}), $!\n";
                exit ($!);
            }

            # wait for the child threads to return, we set a flag that we need to link - it's false
            # by default, and will only be set to true if some files needed to be compiled, and they
            # were all successful.
            # XXX TODO: this could be a bit more elegant, right now it blocks on the first thread in
            # XXX TODO: the stack that isn't finished...
            my $linkNeeded = 0;
            my $compilationSuccessful = 1;
            while (scalar (@threads) > 0) {
                $linkNeeded = 1;
                my $result = shift (@threads)->join ();
                $compilationSuccessful = $compilationSuccessful & $result;
            }
            $linkNeeded = $linkNeeded & $compilationSuccessful;

            # exit if compilations failed
            exit (1) if (!$compilationSuccessful);

            # check to see if we need to link...
            if ((!-e $targetContext->{outputFile}) || ($linkNeeded & $compilationSuccessful)) {
                if (-e $targetContext->{outputFile}) {
                    unlink ($targetContext->{outputFile});
                }
                my $link = $targetContext->{linker} . " " . $targetContext->{linkerOptions};
                print STDERR "    LINK: $link\n";

                # exit if link fails
                exit ($!) unless (system($link) == 0);
            }

            # check to see if we need to copy dependencies
            if ($targetContext->{copyDependencies} == 1) {
                for my $dependency (@$dependencies) {
                    if ($targets->{$dependency}->{type} eq "sharedLibrary") {
                        print STDERR "    DEPENDENCY: " . $targets->{$dependency}->{outputFile} . "\n";
                        exit($!) if (copy($targets->{$dependency}->{outputFile}, $targetContext->{outputPath}) == 0);
                    }
                }
            }

            # check to see if we need to copy resources
            if (-d "$targetContext->{resourcesFullPath}") {
                print STDERR "    COPY RESOURCES: $targetContext->{resourcesFullPath}\n";
                exit ($!) unless (system("rsync -qa $targetContext->{resourcesFullPath}/* $targetContext->{outputPath}") == 0);
            }
        } else {
            print STDERR "SKIP $target/$configuration (unknown configuration)\n";
        }
    }
}

#---------------------------------------------------------------------------------------------------
