use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "Magpie", context => $context, pipeline => [
        machine {
            match qr|^/| => ['Magpie::Pipeline::CurlyArgs' => { simple_argument => 'FRIST' }];
            match( qr|^/myapp| => [
                'Magpie::Pipeline::Moe',
                'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' },
                match( qr|/special| => [
                    reset_pipeline,
                    'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'SPECIAL' },
                ]),
                'Magpie::Pipeline::Larry'
            ]);
        }
    ]
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