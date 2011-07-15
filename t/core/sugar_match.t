use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;
use Data::Dumper::Concise;

my $handler = builder {
    enable "Magpie", context => {}, pipeline => [
        machine {
            match '/myapp' => ['Core::Basic::Base', 'Core::Basic::Output'];
        },
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/foo");
            unlike $res->content, qr/basic::base::event_init/;
            unlike $res->content, qr/basic::base::event_first/;
            unlike $res->content, qr/basic::base::event_last/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp");
            like $res->content, qr/basic::base::event_init/;
            unlike $res->content, qr/basic::base::event_first/;
            unlike $res->content, qr/basic::base::event_last/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp?appstate=first");
            like $res->content, qr/basic::base::event_init/;
            like $res->content, qr/basic::base::event_first/;
            unlike $res->content, qr/basic::base::event_last/;
        }
        {
            my $res = $cb->(GET "http://localhost/myapp?appstate=last");
            like $res->content, qr/basic::base::event_init/;
            like $res->content, qr/basic::base::event_last/;
            unlike $res->content, qr/basic::base::event_first/;
        }
#
    };

done_testing();

=cut
machine {
    match '/'       =>  [qw(RootMatch)];
    match qr!/foo/! => [qw(That Regexp Matched)];
    match_env { REQUEST_METHOD => 'GET', SERVER_NAME => qr/^local/ } =>     ['EnvMatch'];
    match_env sub {
        my $env = shift;
        warn Data::Dumper::Concise::Dumper( $env );
        return [qw(From Inside The House)]
    };
    match qr!/stooges! => [
        'Magpie::Pipeline::Moe',
        'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' }, 'Magpie::Pipeline::Larry',
    ];
};