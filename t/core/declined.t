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
        'Core::Declined::StepOne',
        'Core::Declined::StepTwo',
        'Core::Basic::Output',
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/?appstate=first");
            like $res->content, qr/declined::StepOne::event_init/;
            unlike $res->content, qr/declined::StepOne::event_first/;
            like $res->content, qr/declined::StepTwo::event_init/;
            like $res->content, qr/declined::StepTwo::event_first/;
        }
    };

done_testing();

=cut
sub test_output {
    my $resp = GET '/output?appstate=first';
    my $output = $resp->content;
    return 0 unless $output =~ /output::StepOne::event_init/;
    return 0 if $output =~ /output::StepOne::event_first/;
    return 0 if $output =~ /output::StepTwo::event_init/;
    return 0 if $output =~ /output::StepTwo::event_first/;
    return 1;
}

sub test_redirect {
    my $resp = GET '/redirect?appstate=first';
    if ( $resp->isa('Apache::TestClientResponse') ) {
        return 1; # braindead user agent
        return 0 unless $resp->code == 302;
    }
    else {
        return 0 unless my $prev =  $resp->previous();
        return 0 unless $prev->is_redirect;
    }
    return 1;
}
