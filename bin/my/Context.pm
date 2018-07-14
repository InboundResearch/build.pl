use strict;
use warnings FATAL => 'all';

# need JsonFile - the search lib path has already been adjusted by the calling perl script, so we
# don't need to do that again here.
use JsonFile;

package Context;

# export parts so they can be used without qualification
use Exporter qw(import);
our @EXPORT = ();
our @EXPORT_OK = qw(%ContextType reduce apply concatenate conf);

# given a value and a context, reduce the value as much as possible by performing replacements
# XXX TODO - this needs to be a bit more fantastical
sub replaceValues {
    my ($value, $context) = @_;

    # do variable substitutions, .
    my $replacementCount;
    do {
        $replacementCount = 0;
        # this list is reverse sorted so that variable names that are substrings of longer variable
        # names will be replaced after the longer variable names are replaced, hopefully this isn't
        # just too clever by half.
        my @variableNames = reverse sort $value =~ /\$([a-z][A-Za-z0-9]*)/g;
        for my $variableName (@variableNames) {
            if ((exists($context->{$variableName})) && ($context->{$variableName} ne "*")) {
                $value =~ s/\$$variableName/$context->{$variableName}/ge;
                ++$replacementCount;
            }
        }
    } while (0);#($replacementCount > 0);

    # do a substitution with a shell command if one is requested, until no more happen
    while ($value =~ s/\$\(([^\)]*)\)/my $x = qx%$1%; chomp $x; $x/e) {}

    # return the reduced value
    return $value;
}

sub reduce {
    my ($context) = @_;
    # make a shallow copy of the context
    my $new = {%$context};

    # iterate over all the keys
    # XXX TODO - need to do this repeatedly until no more values change
    for my $key (keys (%$new)) {
        # allow for "reduce" to result in undef
        my $value = replaceValues ($new->{$key}, $new);
        if ($value ne $new->{$key}) {
            $new->{$key} = $value;
        }
    }
    return $new;
}

# given a left context and a right context, create a new context that "applies" left to right,
# where right contains variable names needing substitution, and left possibly supplies values.
sub apply {
    my ($left, $right) = @_;

    my $new = {};
    for my $key (keys (%$right)) {
        # allow for "reduce" to result in undef
        my $value = replaceValues ($right->{$key}, $left);
        if (defined $value) {
            $new->{$key} = $value;
        }
    }
    for my $key (keys (%$left)) {
        if (! exists ($new->{$key})) {
            $new->{$key} = $left->{$key};
        }
    }
    return $new;
}

# apply an array of contexts left to right
sub concatenate {
    my $result = {};
    for my $context (@_) {
            $result = apply ($result, $context);
    }
    return $result;
}

sub display {
    my ($context) = @_;
    for my $key (sort keys %$context) {
        print STDERR "$key: ($context->{$key})\n";
    }
    print STDERR "\n";
    return $context;
}

#---------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS FOR WORKING WITH STORED CONTEXTS

our %ContextType = (
    BUILD          => "build",
    VALUES         => "values",
    CONFIGURATIONS => "configurations",
    TYPES          => "types"
);

my %contexts;

# add a named context to the global context store
sub addNamed {
    my ($name, $context) = @_;
    $contexts{$name} = $context;
    return $context;
}

sub addTypeNamed {
    my ($baseName, $type, $context) = @_;
    return addNamed ("$baseName-$type", $context);
}

# get a named context from the global context store, or return an empty context
sub getNamed {
    my ($name) = @_;
    return $contexts{$name} || {};
}

sub getTypeNamed {
    my ($baseName, $type) = @_;
    return getNamed ("$baseName-$type");
}

# get a value from a named context
sub conf {
    my ($name, $variableName) = @_;
    return getNamed($name)->{$variableName};
}

sub confType {
    my ($baseName, $type, $variableName) = @_;
    return getTypeNamed($baseName, $type)->{$variableName};
}

# concatenate an array of named contexts
sub concatenateNamed {
    my @contexts;
    for my $contextName (@_) {
        push (@contexts, getNamed($contextName));
    }
    return concatenate (@contexts);
}

# load a context file, without regard to its contents
sub loadFile {
    my ($baseName, $path, $type) = @_;
    my $context = JsonFile::read("$path/$type.json");
    return addTypeNamed ($baseName, $type, $context);
}

# load a context file, and then break it into its parts
sub load {
    my ($baseName, $configPath) = @_;
    my $context = loadFile ($baseName, $configPath, $ContextType{BUILD});
    addTypeNamed($baseName, $ContextType{VALUES}, $context->{$ContextType{VALUES}});
    addTypeNamed($baseName, $ContextType{CONFIGURATIONS}, $context->{$ContextType{CONFIGURATIONS}});
    addTypeNamed($baseName, $ContextType{TYPES}, $context->{$ContextType{TYPES}});
    return $context;
}

# stupid utility function to print a context
sub displayNamed {
    my ($name) = @_;
    print STDERR "CONTEXT ($name)\n";
    return display (getNamed($name));
}

sub displayTypeNamed {
    my ($baseName, $type) = @_;
    print STDERR "CONTEXT ($baseName-$type)\n";
    return display (getTypeNamed($baseName, $type));
}

1;
