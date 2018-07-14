use strict;
use warnings FATAL => 'all';

package Slurp;

# export the 'slurp' function so it can be used without qualification
use Exporter 'import';
our @EXPORT_OK = qw(slurp);

sub slurp {
    my ($filename) = @_;
    open (INPUT, $filename) || die "can't open $filename: $!";
    my $contents = undef;
    while (<INPUT>) {
        chomp;
        $contents .= $_;
    }
    close(INPUT) || die "can't close $filename: $!";
    return $contents;
}

1;
