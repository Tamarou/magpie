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

my $style_path = 't/htdocs/stylesheets';

my $handler = builder {
    enable "Magpie", pipeline => [
        machine {
            match qr|^/blog/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/blog.xsl" }, ];
            match qr|^/shop/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/shop.xsl" }, ];
            match qr|^/| => [ 'Magpie::Transformer::XSLT' =>
                    { stylesheet => "$style_path/alternates/wrapper.xsl" }, ];
        }
    ];
    enable "Static", path => qr!\.xml$!, root => './t/htdocs/alternates';
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $req = HTTP::Request->new(
            GET => "http://localhost/shop/index.xml?testparam=wooo" );
        my $res = $cb->($req);
        like $res->content, qr/Hello Shopper!/;
        like $res->content, qr/wooo/;
        like $res->content, qr/Header/;
        like $res->content, qr/Footer/;
    }
    {
        my $req = HTTP::Request->new(
            GET => "http://localhost/blog/index.xml?testparam=wooo" );
        my $res = $cb->($req);
        like $res->content, qr/Hello DFH!/;
        like $res->content, qr/wooo/;
        like $res->content, qr/Header/;
        like $res->content, qr/Footer/;
    }

    };

done_testing;
