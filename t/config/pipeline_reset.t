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

my $handler = builder {
    enable "Magpie", conf => 't/data/pipeline_reset.xml'
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/myapp");
            like $res->content, qr/^_curlyfoo_FRIST_moebaz__moebar__curlyfoo_RIGHT_larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp/special");
            like $res->content, qr/^_curlyfoo_SPECIAL_larryfoo__larrybar_\b/;
        }

    };

done_testing();