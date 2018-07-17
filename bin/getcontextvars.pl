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

if ($ARGV[0] eq "projects") {
    my $sourcePath = Context::confType ("project", $ContextType{VALUES}, "sourcePath");
    if (opendir(SOURCE_PATH, $sourcePath)) {
        my $separator = "";
        while (my $target = readdir(SOURCE_PATH)) {
            # skip unless $target is a non-hidden directory, that is not also the build directory
            next unless (($target !~ /^\./) && (-d "$sourcePath/$target"));
            next if (abs_path("$sourcePath/$target") eq abs_path(Context::confType("project", $ContextType{VALUES}, "buildPath")));
            print "$separator$target";
            $separator = ",";
        }
        print "\n";
        closedir(SOURCE_PATH);
    }
    else {
        print STDERR "Can't open source directory ($sourcePath), $!\n";
    }
} else {
    my $result = Context::confType ("project", $ContextType{VALUES}, $ARGV[0]);
    if (defined $result) {
        print "$result\n";
        exit (0);
    }
    print "UNDEFINED\n";
    exit (1);
}
