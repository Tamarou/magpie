use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", pipeline => [
        'Magpie::Transformer::XSP'
    ];

    enable "Static", path => qr!\.xsp$!, root => './t/htdocs';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/avt.xsp");
        my $res = $cb->($req);
        my $body = $res->content;
        warn $body;
        like( $body, qr(test="655321") );
        like( $body, qr(test="droogie_655321") );
        like( $body, qr(test="6553210") );
        like( $body, qr(test="123556-655321") );
        like( $body, qr(test="bar") );
};

done_testing;
