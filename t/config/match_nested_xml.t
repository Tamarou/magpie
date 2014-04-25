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
    enable "Magpie", conf => 't/data/match_nested.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/myapp");
            like $res->content, qr/_moebaz__moebar__larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp/right");
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT_larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp/wrong");
            like $res->content, qr/_moebaz__moebar__curlyfoo_WRONG_larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp/pernicious");
            like $res->content, qr/_moebaz__moebar__larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp/wrong/pernicious");
            like $res->content, qr/_moebaz__moebar__curlyfoo_WRONG_curlyfoo_TERRIBLE_larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/store/aabbcc");
            like $res->content, qr/^pathmadness__store_id::aabbcc_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/store/ddeeff/1234");
            like $res->content, qr/^pathmadness__store_id::ddeeff_pathmadness__product_id::1234__store_id::ddeeff_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/env",  Accept => 'text/plain' );
            like $res->content, qr/_moebaz__moebar__curlyfoo_PLAIN_larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/env",  Accept => 'text/xml' );
            like $res->content, qr/_moebaz__moebar__curlyfoo_XML_larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/env");
            like $res->content, qr/_moebaz__moebar__larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://faketld/env");
            like $res->content, qr/_larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/accept/", Accept => 'application/x-xml', 'Accept-Language' => 'de; q=1.0, en; q=0.5');
            like $res->content, qr/_moebaz__moebar__larryfoo__larrybar_\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/accept/", Accept => 'text/plain', 'Accept-Language' => 'de; q=1.0, en; q=0.5');
            like $res->content, qr/_moebaz__moebar__curlyfoo_DANKE_larryfoo__larrybar_\b/;
        }

    };

done_testing();