use strict;
use warnings;
use Test::More;


use FindBin;
use lib "$FindBin::Bin/lib";
# use Plack::Test;
# use Plack::Builder;
# use Plack::Middleware::Magpie;
use Loader;
use Data::Printer;
use Scalar::Util qw(reftype blessed);

my @wev = machine {
   match '/'       =>  [qw(RootMatch)];
   match qr!/foo/! => [qw(That Regexp Matched)];
   match_env { 'string' => 'literal', 'match' => qr/^(this|that)$/ } => ['EnvMatch'];
};

warn "returned " . p(@wev);

 my ($thing) = grep { $_->[0] eq 'HASH' } @wev;

 warn "thing " . p($thing);

my $hash = $thing->[1];

foreach my $k (keys %$hash ) {
    my $v = $hash->{$k};
    my $t = reftype $v;
    warn "$k is $v of type $t\n";
}
# foreach my $frame (@wev) {
#     my $size = scalar @{$frame->[2]};
#     warn sprintf "size of %s is %s\n", $frame->[1], $size;
# }
ok 1;

done_testing;
