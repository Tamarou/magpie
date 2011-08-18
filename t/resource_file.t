use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

# my $handler = builder {
#     enable "Magpie", resource => 'Magpie::Resource::File';
# };
#
# test_psgi
#     app    => $handler,
#     client => sub {
#         my $cb = shift;
#         {
#             my $resp = $cb->(GET "http://localhost/t/htdocs/hello.xml");
#             is $resp->code, 200;
#             like $resp->content, qr|<hello/>|;
#         }
#         {
#             my $resp = $cb->(GET "http://localhost/t/htdocs/avt.xsp");
#             is $resp->code, 200;
#             like $resp->content, qr|<xsp:logic>|;
#         }
#     };

my $handler2 = builder {
    enable "Magpie", resource => { class => 'Magpie::Resource::File', root => 't/htdocs' };
};

test_psgi
    app    => $handler2,
    client => sub {
        my $cb = shift;
        {
            my $resp = $cb->(GET "http://localhost/hello.xml");
            is $resp->code, 200;
            like $resp->content, qr|<hello/>|;
        }
        {
            my $resp = $cb->(GET "http://localhost/avt.xsp");
            is $resp->code, 200;
            like $resp->content, qr|<xsp:logic>|;
        }
    };

done_testing;
