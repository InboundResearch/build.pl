use strict;
use warnings FATAL => 'all';

package JsonFile;

# JSON handling
use JSON; # imports encode_json, decode_json, to_json and from_json.
my $json = JSON->new->allow_nonref;
$json = $json->pretty(1);

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
