use strict;
use warnings;
use Test::More;

use Test::Requires qw{
    XML::LibXSLT
};

use FindBin;
use lib "$FindBin::Bin/lib";
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $style_path = '/stylesheets';

my $handler = builder {
    enable "Magpie",
        resource =>
        { class => 'Magpie::Resource::File', root => './t/htdocs' },
        pipeline => [
        machine {
            match qr|^/xinclude/blog/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/blog.xsl" }, ];
            match qr|^/xinclude/shop/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/shop.xsl" }, ];
            match qr|^/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/wrapper.xsl" }, ];
        }
        ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $res = $cb->(
            GET "http://localhost/xinclude/shop/index.xml?testparam=wooo" );
        like $res->content, qr/Hello Shopper!/;
        like $res->content, qr/wooo/;
        like $res->content, qr/Header/;
        like $res->content, qr/Footer/;
        like $res->content, qr/Included text/;

    }
    {
        my $req = HTTP::Request->new( GET =>
                "http://localhost/xinclude/blog/index.xml?testparam=wooo" );
        my $res = $cb->($req);
        like $res->content, qr/Hello DFH!/;
        like $res->content, qr/wooo/;
        like $res->content, qr/Header/;
        like $res->content, qr/Footer/;
        like $res->content, qr/Included text/;
    }

    };

done_testing;
