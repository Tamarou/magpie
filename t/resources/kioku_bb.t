use strict;
use warnings;
use Test::More;
use Test::Requires qw{
    KiokuX::Model
    DBD::SQLite
};

use FindBin;
use lib "$FindBin::Bin/lib";
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;
use Bread::Board;


my $handler = builder {
    enable "Magpie", pipeline => [
        machine {
            match qr|/orders/| => [
                'Magpie::Resource::Kioku' => {
                    dsn        => "dbi:SQLite::memory:",
                    extra_args => { create => 1 },
                    wrapper_class => 'Magpie::Pipeline::Resource::Kioku::User',
                },
            ];
        }
    ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $res = $cb->( GET "http://localhost/orders/655321" );
        is $res->code, 404;
    }
    };

done_testing;
