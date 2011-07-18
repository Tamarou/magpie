use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

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

    };

done_testing();