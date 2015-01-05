
try mkdir 'install';
try mkdir 'install/languages';
try mkdir 'install/languages/perl6';
try mkdir 'install/languages/perl6/site';
try mkdir 'install/languages/perl6/site/panda';

my $state-file    = 'install/languages/perl6/site/panda/state';
my $projects-file = 'install/languages/perl6/site/panda/projects.json';

fetch-projects-json($projects-file);

my $projects = from-json $projects-file.IO.slurp;

# In case we ship a project that is just a fork of a project listed in the ecosystem, add
# the mapping here.
my %ex =
#    'git://github.com/FROGGS/perl6-digest-md5' => 'git://github.com/cosimo/perl6-digest-md5',
;

# Walk the submodules and put its project information in panda's state file.
my $fh = $state-file.IO.open(:w);
for '.gitmodules'.IO.lines.grep(/^\turl/).map({ /$<url>=[\S+]$/; ~$<url> }) -> $url {
    my $p          = $projects.first({$_.<source-url> ~~ /^ "{%ex{$url} // $url}" '.git'? $/});
    $p<repo-type>  = 'git';
    $p<source-url> = $url;
    $fh.say: $p<name> ~ ' installed ' ~ to-json($p).subst(/\n+/, '', :g);
}
$fh.close;

say $state-file;
say $projects-file;

sub fetch-projects-json($to) {
    try unlink $to;
    my $s;
    if %*ENV<http_proxy> {
        my ($host, $port) = %*ENV<http_proxy>.split('/').[2].split(':');
        $s = IO::Socket::INET.new(host=>$host, port=>$port.Int);
        $s.send("GET http://feather.perl6.nl:3000/projects.json HTTP/1.1\nHost: feather.perl6.nl\nAccept: */*\nConnection: Close\n\n");
    }
    else {
        $s = IO::Socket::INET.new(:host<feather.perl6.nl>, :port(3000));
        $s.send("GET /projects.json HTTP/1.0\n\n");
    }
    my ($buf, $g) = '';
    $buf ~= $g while $g = $s.get;

    if %*ENV<http_proxy> {
        $buf.=subst(:g,/'git://'/,'http://');
    }
    
    given open($to, :w) {
        .say: $buf.split(/\r?\n\r?\n/, 2)[1];
        .close;
    }
}
