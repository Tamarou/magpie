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
        qw(
            Magpie::Pipeline::Moe
            Magpie::Pipeline::Larry
            Magpie::Pipeline::Curly
            )
    ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/" );
    my $res = $cb->($req);
    like $res->content, qr/_moebaz__moebar__larryfoo__larrybar__curlyfoo_/;
    };

done_testing;
