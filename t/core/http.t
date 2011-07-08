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

            $res = $cb->(GET 'http://localhost/?appstate=cookie');
            warn $res->content;
        }
    };


done_testing();
=cut
##
sub test_get {
    my $resp = GET '/http' ;
    return 0 unless $resp->content =~ /howdy/i;
    return 1;
}

sub test_cookie {
    my $resp = GET '/http?appstate=cookie' ;
    if ( $resp->isa('Apache::TestClientResponse')) {
        my $headers = $resp->headers;
        return 0 unless defined($headers->{'set-cookie'});
    }
    else {
        return 0 unless $resp->headers->as_string =~ /Set-Cookie:/gi;
    }
    return 1;
}


sub test_multicookie {
    my $resp = GET '/http?appstate=multicookie' ;
    if ( $resp->isa('Apache::TestClientResponse')) {
        my $headers = $resp->headers;
        return 0 unless defined($headers->{'set-cookie'});
    }
    else {
        my $head = $resp->headers->as_string;
        return 0 unless $head =~ /oreo/;
        return 0 unless $head =~ /peanutbutter/;
    }
    return 1;
}

sub test_headers {
    my $resp = GET '/http?appstate=headers';
    if ( $resp->isa('Apache::TestClientResponse')) {
        my $headers = $resp->headers;
        return 0 unless defined($headers->{'x-wibble'});
        return 0 unless defined($headers->{'bogus'});
        return 0 unless $headers->{'content-type'} =~ /text\/xml/i;
    }
    else {
        my $head = $resp->headers->as_string;
        #warn $head;
        return 0 unless $head =~ /x-ubu/;
        return 0 unless $head =~ /arbitrary/;
        return 0 unless $head =~ /text\/xml/;
        return 0 unless $head =~ /UTF-8/;
    }
    return 1;
}

sub test_redirect {
    my $resp = GET '/http?appstate=redirect' ;
    if ( $resp->isa('Apache::TestClientResponse')) {
        return 0 unless $resp->code == 302;
    }
    else {
        return 0 unless my $prev =  $resp->previous();
        return 0 unless $prev->is_redirect;
    }
    return 1;
}

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
