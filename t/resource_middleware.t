use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", pipeline => [qw( Magpie::Pipeline::Resource::Basic)];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $resp = $cb->($req);
        is( $resp->code, 200);
        is( $resp->content, 'GET succeeded!');
    };

done_testing;
