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
        'Core::Output::StepOne',
        'Core::Output::StepTwo',
        'Core::Basic::Output',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/?appstate=first");
            like $res->content, qr/output::StepOne::event_init/;
            unlike $res->content, qr/output::StepOne::event_first/;
            unlike $res->content, qr/output::StepTwo::event_init/;
            unlike $res->content, qr/output::StepTwo::event_first/;
        }
    };

done_testing();
