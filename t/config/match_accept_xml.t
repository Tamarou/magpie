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

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "Magpie", context => $context, conf => 't/data/match_accept.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/",  Accept => 'text/plain', 'Accept-Language' => 'DE,en,fr;Q=0.5,es;q=0.1' );
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT_actually__is__is_frequently__larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/", Accept => 'application/x-xml', 'Accept-Language' => 'DE,en,fr;Q=0.5,es;q=0.1');
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/", 'Accept-Language' => 'en,fr;Q=0.5,es;q=0.1');
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT_larryfoo__larrybar__actually__is__is_frequently_\b/;
        }
    };


done_testing();
