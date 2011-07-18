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
    enable "Magpie", resource => 'Magpie::Resource::File';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $resp = $cb->(GET "http://localhost/t/htdocs/hello.xml");
        is $resp->code, 200;
        like $resp->content, qr|<hello/>|;
    };

done_testing;
