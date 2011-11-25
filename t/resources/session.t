#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use Bread::Board;
use HTTP::Request::Common qw(GET POST DELETE);

use Magpie::Pipeline::Resource::Kioku::User;

my %user = (
    id       => 'ubu',
    password => 'test',
    status   => 'dubious at best',
);

my $assets = container '' => as {
    service 'kioku_dir' => (
        lifecycle => 'Singleton',
        block     => sub {
            my $s = shift;
            KiokuDB->connect( "dbi:SQLite::memory:", create => 1, );
        },
    );
};

my $handler = builder {
    enable "Session";
    enable "Magpie",
        assets   => $assets,
        pipeline => [
        machine {
            match qr|/session| => [ 'Magpie::Resource::Session' => {} ];
            match qr|/users| => [
                'Magpie::Resource::Kioku' => {
                    wrapper_class => 'Magpie::Pipeline::Resource::Kioku::User'
                }
            ];
        }
        ];
};

test_psgi $handler => sub {
    my $cb = shift;

    # Create User
    my $res = $cb->( POST '/users' => [%user] );

    # Create Session
    $res
        = $cb->( POST '/session', [ username => 'ubu', password => 'test' ] );
    is $res->code, '201', 'got the expected code (201)';
    like $res->header('Location'), qr|http://localhost/session/\w+|,
        'response location looks correct';

    # Get the Session Resource
    my $location = $res->header('Location');
    my $cookie   = $res->header('Set-Cookie');
    $res = $cb->( GET $location, Cookie => $cookie );
    is $res->code, 200, 'got the expected code (200)';

TODO: {
        local $TODO
            = 'DELETE is not getting dispatched properly';
        $res = $cb->( DELETE $location, Cookie => $cookie );
        is $res->code, 302, 'got the expected code (302)';
    }
};

done_testing;
