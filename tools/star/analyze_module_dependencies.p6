my %depended-on := SetHash.new;
my @has-names;

use JSON::Fast;

for qx{ ls modules/*/META* }.lines -> $jf {

    my $data = from-json(slurp($jf));

    # list module as available
    @has-names.push($data<name>);

    # these three can contain dependencies
    for <depends test-depends build-depends> -> $_ {
        # but some of them are optional
        next unless $data{$_}:exists;
        my $val = $data{$_};
        # and sometimes they are just an empty array in the json blob.
        next if $val.elems == 0;

        # record every dependency in our set
        %depended-on{@$val}>>++;
    }
}

# exclude a few modules:
# Panda doesn't have a META.info
# Test is shipped with Rakudo
# NativeCall is also shipped with rakudo
# nqp isn't really a module.
my @missing = %depended-on (-) @has-names (-) <Panda Test NativeCall nqp>;

with @missing {
    say "There are some modules that are depended on, but not in the modules list.";
    .say for @missing;
} else {
    say "the modules seem to be sane.";
}
