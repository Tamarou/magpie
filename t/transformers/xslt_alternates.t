use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require XML::LibXSLT; };
    if ( $@ ) {
        plan skip_all => 'XML::LibXSLT is not installed, cannot continue.'
    }
};

use FindBin;
use lib "$FindBin::Bin/lib";
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;

my $style_path = 't/htdocs/stylesheets';

my $handler = builder {
    mount '/blog' => enable "Magpie",
        pipeline => [
            'Magpie::Transformer::XSLT' => { stylesheet  => "$style_path/alternates/blog.xsl" },
        ];
#     mount '/shop' => enable "Magpie",
#         pipeline => [
#             'Magpie::Transformer::XSLT' => { stylesheet  => "$style_path/alternates/shop.xsl" },
#         ];

    mount => '/' => enable "Static", path => qr!\.xml$!, root => './t/htdocs';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => "http://localhost/blog/hello.xml?testparam=wooo");
            my $res = $cb->($req);
            warn $res->content;
            like( $res->content, qr(Hello Magpie!) );
            like( $res->content, qr(wooo) );
        }
    };

done_testing;
