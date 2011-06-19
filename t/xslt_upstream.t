use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;

my $handler = builder {
    enable "Magpie", pipeline => [
        'Magpie::Transformer::XSLT' => { stylesheet => 't/htdocs/stylesheets/hello.xsl' }
    ];

    enable "Static", path => qr!\.xml$!, root => './t/htdocs';
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/hello.xml");
        my $res = $cb->($req);
        like( $res->content, qr(Hello Magpie!) );
    };

done_testing;
