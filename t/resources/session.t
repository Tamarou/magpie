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
use HTTP::Request::Common;
use Plack::Session::Store::Cache;
use CHI;

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
    enable "Session", Plack::Session::Store::Cache->new(
        cache => CHI->new( driver => 'FastMmap', )    #
    );
    enable "Magpie",
        assets   => $assets,
        pipeline => [
        machine {
            match qr[/(?:login|session)] =>
                [ 'Magpie::Resource::Session' => {} ];
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
    $res = $cb->( POST '/login', [ username => 'ubu', password => 'test' ] );
    warn $res->dump;
    is $res->code, '303', 'got the expected code (303)';
    like $res->header('Location'), qr|/session/[\w]+|,
        'response location looks correct';

    # Get the Session Resource
    my $location = $res->header('Location');
    my $cookie   = $res->header('Set-Cookie');
    $res = $cb->( GET $location, Cookie => $cookie );
    is $res->code, 302, 'got the expected code (302)';
    like $res->header('Location'), qr|/|, 'response location looks correct';

};

done_testing;
