use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use Bread::Board;
use HTTP::Request::Common;

my $assets = container '' => as {
    service 'somevar' => 'some value';
};

my $handler = builder {
    enable "Magpie",
        assets   => $assets,
        pipeline => [
        'Magpie::Pipeline::Moe',
        'Magpie::Pipeline::Breadboard::Simple',
        'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' },
        'Magpie::Pipeline::Larry',
        ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb  = shift;
    my $res = $cb->( GET "http://localhost/" );
    like $res->content,
        qr/_moebaz__moebar__simplefoo__some value__simplebaz__curlyfoo_RIGHT_larryfoo__larrybar_/;
    };

done_testing;
