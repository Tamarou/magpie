use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "Magpie", context => $context, pipeline => [
        'Magpie::Pipeline::Moe',
        'Plack::Middleware::TestComponent' => { some_arg => 'MW' },
        'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' },
        'Magpie::Pipeline::ContextHash',
        'Magpie::Pipeline::Larry',
        'Plack::Middleware::ContentMD5',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/some/path/to/wev");
        like $res->content, qr/_moebaz__moebar__MW__curlyfoo_RIGHT_actually__is__is_frequently__larryfoo__larrybar_/;
        is defined $res->headers('content-md5'), 1;
    };

done_testing();