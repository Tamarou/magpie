use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $handler = builder {
    enable "Magpie", pipeline => [qw( Magpie::Pipeline::Resource::Basic)];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $resp = $cb->(GET "http://localhost/");
        is $resp->code, 200;
        is $resp->content, 'GET succeeded!';
    };

done_testing;
