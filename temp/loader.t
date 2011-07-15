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
use Plack::Request;
use Scalar::Util qw(reftype blessed);

my $fake_env = {
  CONTENT_LENGTH => 0,
  PATH_INFO => "/",
  QUERY_STRING => "appstate=last",
  REMOTE_ADDR => "127.0.0.1",
  REMOTE_HOST => "localhost",
  REMOTE_PORT => 49474,
  REQUEST_METHOD => "GET",
  REQUEST_URI => "/stooges/fooled/me.html?appstate=last",
  SCRIPT_NAME => "",
  SERVER_NAME => "localhost",
  SERVER_PORT => 80,
  SERVER_PROTOCOL => "HTTP/1.1",
  "psgi.errors" => *::STDERR,
  "psgi.input" => \'',
  "psgi.multiprocess" => "",
  "psgi.multithread" => "",
  "psgi.nonblocking" => "",
  "psgi.run_once" => 1,
  "psgi.streaming" => 1,
  "psgi.url_scheme" => "http",
  "psgi.version" => [
    1,
    1
  ]
};

my @wev = machine {
    match '/'       =>  [qw(RootMatch)];
    match qr!/foo/! => [qw(That Regexp Matched)];
    match_env { REQUEST_METHOD => 'GET', SERVER_NAME => qr/^local/ } =>     ['EnvMatch'];
    match_env sub {
        my $env = shift;
        warn Data::Dumper::Concise::Dumper( $env );
        return [qw(From Inside The House)]
    };
    match qr!/stooges! => [
        'Magpie::Pipeline::Moe',
        'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' }, 'Magpie::Pipeline::Larry',
    ];
};

warn "returned " . p(@wev);

my $r = Plack::Request->new($fake_env);

ok($r);

my $wev = Loader::build_machine( $r );

warn "built " . p($wev);


# my ($thing) = grep { $_->[0] eq 'HASH' } @wev;
#
# warn "thing " . p($thing);
#
# my $hash = $thing->[1];
#
# foreach my $k (keys %$hash ) {
#     my $v = $hash->{$k};
#     my $t = reftype $v;
#     warn "$k is $v of type $t\n";
# }
# foreach my $frame (@wev) {
#     my $size = scalar @{$frame->[2]};
#     warn sprintf "size of %s is %s\n", $frame->[1], $size;
# }
ok 1;

done_testing;
