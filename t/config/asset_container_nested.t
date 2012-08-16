use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "Magpie", context => $context, conf => 't/data/asset_container_nested.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/basic?appstate=nestedcontainer");
            like $res->content,
        qr/_moebaz__moebar__sm1__some name_baz_Christmas__sm2__some name_RAAAaaam_Easter__curlyfoo_RIGHT_larryfoo__larrybar_/;
        }
    };


done_testing();
