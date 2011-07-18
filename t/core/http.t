use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;
#use Data::Dumper::Concise;

my $handler = builder {
    enable "Magpie", context => {}, pipeline => [
        'Core::HTTP::Base',
        'Core::Basic::Output',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            like $res->content, qr/Howdy/;
        }
        {
            my $res = $cb->(GET 'http://localhost/?appstate=cookie');
            like $res->headers->as_string, qr/Set-Cookie/;
        }
        {
            my $res = $cb->(GET 'http://localhost/?appstate=multicookie');
            my $head = $res->headers->as_string;
            like $head, qr/oreo/;
            like $head, qr/peanutbutter/;
        }
        {
            my $res = $cb->(GET 'http://localhost/?appstate=headers');
            my $head = $res->headers->as_string;
            like $head, qr/Content-Encoding:\s+UTF-8/;
            like $head, qr|Content-Type:\s+text/xml|;
            like $head, qr/Bogus:\s+arbitrary/;
            like $head, qr|X-Wibble:\s+text/x-ubu|;
        }
        {
            my $res = $cb->(GET 'http://localhost/?appstate=redirect');
            is $res->code, 302;
        }
        {
            my $res = $cb->(GET 'http://localhost/?appstate=redirect_cookie');
            my $head = $res->headers->as_string;
            is $res->code, 302;
            like $head, qr/Set-Cookie/;
        }

    };

done_testing();