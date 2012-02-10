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
        'Magpie::Pipeline::CurlyArgs' => { traits => [qw(+Magpie::Pipeline::Role::Appender)], reversable => 'regnad kcin', simple_argument => 'RIGHT' },
        'Magpie::Pipeline::ContextHash',
        'Magpie::Pipeline::Larry',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        like $res->content, qr/_moebaz__moebar__curlyfoo_RIGHT__nick danger___actually__is__is_frequently__larryfoo__larrybar_/;
    };

done_testing();
