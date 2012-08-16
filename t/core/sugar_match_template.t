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
        machine {
            match_template '/.+/{store_id}/item/{item_id}' => ['Magpie::Pipeline::PathMadness', 'Magpie::Pipeline::PathMadness'];
        },
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/shop/aaa/item/1234567");
            like $res->content, qr|pathmadness__item_id::1234567__store_id::aaa_pathmadness__item_id::1234567__store_id::aaa_|;
        }
    };

done_testing();