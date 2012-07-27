#! perl

open my $fh, '<', 'VERSION'
    or die "Cannot open VERSION for reading: $!";
my $VERSION = <$fh>; chomp $VERSION;
close $fh;

while (<>) {
    s/PUT-COMPANY-NAME-HERE/Rakudo Perl 6/g;
    s/PUT-PRODUCT-NAME-HERE/Rakudo Star $VERSION/g;
    s/PUT-FEATURE-TITLE-HERE/Rakudo Star $VERSION/g;
    print;
}


