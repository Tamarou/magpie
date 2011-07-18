use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", context => {}, pipeline => [
        'Core::Pipeloader::Chooser',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            like $res->content, qr/chooser::init...chooser::default...moe::init...moe::default.../;
        }
        {
            my $res = $cb->(GET "http://localhost/?appstate=moe");
            like $res->content, qr/chooser::init...chooser::moe...moe::init...moe::moe...larry::init...larry::moe.../;
        }
        {
            my $res = $cb->(GET "http://localhost/?appstate=larry");
            like $res->content, qr/chooser::init...chooser::larry...moe::init...moe::larry...larry::init...larry::larry...curly::init...curly::larry/;
        }
        {
            my $res = $cb->(GET "http://localhost/?appstate=curly");
            like $res->content, qr/chooser::init...chooser::curly...moe::init...moe::curly.../;
            unlike $res->content, qr/larry::/;
        }

    };


done_testing();
