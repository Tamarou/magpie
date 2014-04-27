use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Requires qw{
    KiokuDB
    DBD::SQLite
};

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use Bread::Board;
use HTTP::Request::Common;

my %user = (
    name   => 'ubu',
    status => 'dubious at best',
);

my $assets = container '' => as {
    service 'somevar'   => 'some value';
    service 'kioku_dir' => (
        lifecycle => 'Singleton',
        block     => sub {
            my $s = shift;
            KiokuDB->connect( "dbi:SQLite::memory:", create => 1, );
        },
    );
};

my $handler = builder {
    enable "Magpie",
        assets   => $assets,
        pipeline => [
        machine {
            match qr|/users| => [
                'Magpie::Resource::Kioku' => {
                    wrapper_class => 'Magpie::Pipeline::Resource::Kioku::User'
                },
                'Magpie::Transformer::JSON',
            ];
        }
        ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb  = shift;
    my $url = "http://localhost/users";
    my $created_url = undef;
    {
        my $res = $cb->( POST $url => \%user );

        is $res->code, 201, "correct response code";
        $created_url = $res->header('Location');
        ok defined $created_url;
    }
    {
        if ($created_url) {
            my $res = $cb->( GET $created_url);
            is $res->code, 200, "correct GET response.";
            like $res->content, qr|ubu|, 'JSON serialized';
        }
        else {
         fail "GET to follow-on URL failed."
        }
    }
    };

ok(1);
done_testing;
