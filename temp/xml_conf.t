use strict;
use warnings;
use Test::More;


use FindBin;
use lib "$FindBin::Bin/lib";
use Magpie::Config::XML;
use Data::Printer;
use Plack::Request;
use Scalar::Util qw(reftype blessed);

# my $fake_env = {
#   CONTENT_LENGTH => 0,
#   PATH_INFO => "/",
#   QUERY_STRING => "appstate=last",
#   REMOTE_ADDR => "127.0.0.1",
#   REMOTE_HOST => "localhost",
#   REMOTE_PORT => 49474,
#   REQUEST_METHOD => "GET",
#   REQUEST_URI => "/stooges/fooled/me.html?appstate=last",
#   SCRIPT_NAME => "",
#   SERVER_NAME => "localhost",
#   SERVER_PORT => 80,
#   SERVER_PROTOCOL => "HTTP/1.1",
#   "psgi.errors" => *::STDERR,
#   "psgi.input" => \'',
#   "psgi.multiprocess" => "",
#   "psgi.multithread" => "",
#   "psgi.nonblocking" => "",
#   "psgi.run_once" => 1,
#   "psgi.streaming" => 1,
#   "psgi.url_scheme" => "http",
#   "psgi.version" => [
#     1,
#     1
#   ]
# };

my $p = Magpie::Config::XML->new;

my @stack = $p->process('temp/conf.xml');

p(@stack);

ok 1;

done_testing;
