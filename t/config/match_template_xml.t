use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::Requires qw{
    XML::LibXML
};

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", conf => 't/data/match_template.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/shop/aaa/item/1234567");
            like $res->content, qr/pathmadness__item_id::1234567__store_id::aaa_/;
        }
        {
            my $res = $cb->(GET "http://localhost/api/widget/aabbccdd/part/OU812");
            like $res->content, qr|pathmadness__part_id::OU812__widget_id::aabbccdd_|;
        }

    };

done_testing();