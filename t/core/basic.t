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
        'Core::Basic::Base',
        'Core::Basic::Output',
    ];
};

# test_psgi
#     app    => $handler,
#     client => sub {
#         my $cb = shift;
#         {
#             my $res = $cb->(GET "http://localhost/");
#             like $res->content, qr/basic::base::event_init/;
#             unlike $res->content, qr/basic::base::event_first/;
#             unlike $res->content, qr/basic::base::event_last/;
#         }
#         {
#             my $res = $cb->(GET "http://localhost/?appstate=first");
#             like $res->content, qr/basic::base::event_init/;
#             like $res->content, qr/basic::base::event_first/;
#             unlike $res->content, qr/basic::base::event_last/;
#         }
#         {
#             my $res = $cb->(GET "http://localhost/?appstate=last");
#             like $res->content, qr/basic::base::event_init/;
#             like $res->content, qr/basic::base::event_last/;
#             unlike $res->content, qr/basic::base::event_first/;
#         }
#
#     };


my $done_handler = builder {
    enable "Magpie", context => {}, pipeline => [
        'Core::Done::StepOne',
        'Core::Done::StepTwo',
        'Core::Basic::Output',
    ];
};

test_psgi
    app    => $done_handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            warn Dumper( $res );
        }
    };

done_testing();

=cut

sub test_done {
    my $resp = GET '/done?appstate=first';
    #warn "got code: " . $resp->as_string;
    if ( $resp->isa('Apache::TestClientResponse') ) {
        return 1;
    }
    return 0 unless $resp->code == 500 or $resp->content_length == 0;
    return 1;
}

sub test_declined {
    my $resp = GET '/declined?appstate=first';
    my $output = $resp->content;
    return 0 unless $output =~ /declined::StepOne::event_init/ig;
    return 0 if $output =~ /declined::StepOne::event_first/ig;
    return 0 unless $output =~ /declined::StepTwo::event_init/ig;
    return 0 unless $output =~ /declined::StepTwo::event_first/ig;
    return 1;
}

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
