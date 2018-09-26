#! /usr/bin/env perl

use strict;
use warnings FATAL => 'all';
#use diagnostics;

# utf8 everything...
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use utf8;

use File::Basename;
use Cwd qw(abs_path);

# search under the script directory location for the "my" libs
use lib dirname (abs_path(__FILE__)) . "/my";
use Context qw(%ContextType);

#---------------------------------------------------------------------------------------------------
# phase 1 - get the contexts
#---------------------------------------------------------------------------------------------------
# root and project contexts
Context::load ("root", dirname(abs_path(__FILE__)));
Context::load ("project", ".");

# put them all together and replace the project-values context
Context::addTypeNamed("project", $ContextType{VALUES},
    Context::concatenateNamed (
        "root-" . $ContextType{VALUES},
        "project-" . $ContextType{VALUES}
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
my $targetsToBuild = [sort keys (%$targets)];
my $targetsInDependencyOrder = [];
for my $target (@$targetsToBuild) {
    traverseTargetDependencies ($targetsInDependencyOrder, $target, $target);
}

#---------------------------------------------------------------------------------------------------
if ($ARGV[0] eq "targets") {
    # get the targets, as sorted in dependency order
    my $separator = "";
    for my $target (@$targetsInDependencyOrder) {
        print "$separator$target";
        $separator = ",";
    }
    print "\n";
} elsif ($ARGV[0] eq "configurations") {
    my $configurationsHash = Context::concatenate (
        Context::getTypeNamed("root", $ContextType{CONFIGURATIONS}),
        Context::getTypeNamed("project", $ContextType{CONFIGURATIONS})
    );
    my $separator = "";
    for my $configuration (sort keys (%$configurationsHash)) {
        print "$separator$configuration";
        $separator = ",";
    }
    print "\n";
} elsif ($ARGV[0] eq "tools") {
    my $toolsContext = Context::concatenate (
        Context::getTypeNamed("root", $ContextType{TOOLS}),
        Context::getTypeNamed("project", $ContextType{TOOLS})
    );

    # allow for variable substitution in the tools
    my $projectContext = Context::getTypeNamed("project", $ContextType{VALUES});
    $toolsContext = Context::apply($projectContext, $toolsContext);
    if (exists $toolsContext->{$ARGV[1]}) {
        print $toolsContext->{$ARGV[1]} . "\n";
        exit (0);
    }

    print STDERR "UNDEFINED TOOL ($ARGV[1])\nValid tools are: ";
    my $separator = "";
    for my $tool (sort keys (%$toolsContext)) {
        print STDERR "$separator$tool";
        $separator = ", ";
    }
    print STDERR "\n";
    exit (1);
} else {
    my $result = Context::confType ("project", $ContextType{VALUES}, $ARGV[0]);
    if (defined $result) {
        print "$result\n";
        exit (0);
    }
    print STDERR "UNDEFINED VAR ($ARGV[0])\n";
    exit (1);
}
