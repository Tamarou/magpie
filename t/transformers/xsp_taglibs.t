use strict;
use warnings;
use Test::More;

use Test::Requires qw{
    XML::XSP
};

use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $taglibs = {
    'http://axkit.org/NS/xsp/webutils/v1'  => 'XML::XSP::Taglib::WebUtils',
    'http://www.tamarou.com/public/cookie' => 'XML::XSP::Taglib::Cookie',
};

my $handler = builder {
    enable "Magpie", pipeline =>
        [ 'Magpie::Transformer::XSP' => { taglibs => $taglibs }, ];

    enable "Static", path => qr!\.xsp$!, root => './t/htdocs';
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb   = shift;
    my $res  = $cb->( GET "http://localhost/taglibs.xsp" );
    my $body = $res->content;
    is $res->code, '200';
    like $res->header('Set-Cookie'), qr|oreo=doublestuff|;
    like $body, qr|<html>|;
    like $body, qr|http://localhost/taglibs.xsp|;
    };

done_testing;
