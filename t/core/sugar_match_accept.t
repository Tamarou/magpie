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

my $accept = [
    [ 'text_en' => 1.0, 'text/plain', undef, undef, 'en', undef ],
    [ 'text_de' => 1.0, 'text/plain', undef, undef, 'de', undef ],
];

my $handler = builder {
    enable "Magpie", accept_matrix => $accept, context => $context, pipeline => [
        'Magpie::Pipeline::Moe',
        'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' },
        machine {
            match_accept 'text_de' => [
                'Magpie::Pipeline::ContextHash',
                'Magpie::Pipeline::Larry'
            ];
            match_accept 'text_en' => [
                'Magpie::Pipeline::Larry',
                'Magpie::Pipeline::ContextHash',
            ];
        }
    ]
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/",  Accept => 'text/plain', 'Accept-Language' => 'DE,en,fr;Q=0.5,es;q=0.1' );
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT_actually__is__is_frequently__larryfoo__larrybar_/;
        }
        {
            my $res = $cb->(GET "http://localhost/", Accept => 'application/x-xml', 'Accept-Language' => 'DE,en,fr;Q=0.5,es;q=0.1');
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT\b/;
        }
        {
            my $res = $cb->(GET "http://localhost/", 'Accept-Language' => 'en,fr;Q=0.5,es;q=0.1');
            like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT_larryfoo__larrybar__actually__is__is_frequently_\b/;
        }
    };

done_testing();
