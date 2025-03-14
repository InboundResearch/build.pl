use strict;
use warnings FATAL => 'all';

package JsonFile;

# JSON handling
use JSON::PP;
my $json = JSON::PP->new->pretty;

# JSON FILE FUNCTIONS
sub read {
    my ($filename) = @_;
    # print STDERR "Read JSON file ($filename)\n";
    if (open my $JSON_FILE, "<", $filename) {
        local $/ = undef;
        my $jsonString = <$JSON_FILE>;
        close $JSON_FILE;
        #print STDERR "JsonFile - Read $filename\n";
        return $json->decode($jsonString);
    }
    return {};
}

sub write {
    my ($value, $filename) = @_;
    if (open my $JSON_FILE, ">", $filename) {
        print $JSON_FILE $json->encode($value);
        close $JSON_FILE;
        #print STDERR "JsonFile - Wrote $filename\n";
        return 1;
    }
    return 0;
}

1;
