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

my $handler = builder {
    mount '/foo' => builder { enable "Magpie", pipeline => [
        'Magpie::Transformer::XSLT' => { stylesheet => 't/htdocs/stylesheets/hello.xsl' }
    ]};

    mount '/bar' => builder { enable "Magpie", pipeline => [
        'Magpie::Transformer::XSLT' => { stylesheet => 't/htdocs/stylesheets/goodbye.xsl' }
    ]};

    mount '/' => enable "Static", path => qr!\.xml$!, root => './temp/alternate';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => "http://localhost/foo/hello.xml?testparam=wooo");
            my $res = $cb->($req);
            warn $res->content;
            like( $res->content, qr(Hello Magpie!) );
            like( $res->content, qr(wooo) );
       }
        {
            my $req = HTTP::Request->new(GET => "http://localhost/bar/hello.xml?testparam=wooo");
            my $res = $cb->($req);
            warn $res->content;
            like( $res->content, qr(Hello Magpie!) );
            like( $res->content, qr(wooo) );
        }

    };

done_testing;
