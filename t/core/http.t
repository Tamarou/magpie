use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;
use Data::Dumper::Concise;


##
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
=cut

sub test_redirect_cookie {
    my $resp = GET '/http?appstate=redirect_cookie' ;
    if ( $resp->isa('Apache::TestClientResponse')) {
        my $headers = $resp->headers;
        return 0 unless defined($headers->{'set-cookie'});
        return 0 unless $resp->code == 302;
    }
    else {
        return 0 unless my $prev =  $resp->previous();
        return 0 unless $prev->is_redirect;
        return 0 unless $prev->headers->as_string =~ /Set-Cookie:/gi;
    }
    return 1;
}

ok( test_get()              == 1, "Testing Simple Get" );
ok( test_cookie()           == 1, "Testing Cookies Header" );
ok( test_multicookie()      == 1, "Testing Multiple Cookies Header" );
ok( test_headers()          == 1, "Testing outgoing headers" );
ok( test_redirect()         == 1, "Testing redrection" );
ok( test_redirect_cookie()  == 1, "Testing redirection /w cookie" );
