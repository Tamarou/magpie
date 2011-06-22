use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", resource => 'Magpie::Resource::File';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/t/htdocs/hello.xml");
        my $resp = $cb->($req);
        is( $resp->code, 200);
        like( $resp->content, qr(<hello/>) );
    };

done_testing;
