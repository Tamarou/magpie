use strict;
use warnings;
use Test::More;

use Test::Requires qw{
    XML::XSP
};

use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $handler = builder {
    enable "Magpie", pipeline => [ 'Magpie::Transformer::XSP' ];

    enable "Static", path => qr!\.xsp$!, root => './t/htdocs';
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb   = shift;
    my $res  = $cb->( GET "http://localhost/avt.xsp" );
    my $body = $res->content;
    like $body, qr/test="655321"/;
    like $body, qr/test="droogie_655321"/;
    like $body, qr/test="6553210"/;
    like $body, qr/test="123556-655321"/;
    like $body, qr/test="bar"/;
    };

done_testing;
