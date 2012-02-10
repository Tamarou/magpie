use strict;
use warnings;
use Test::More;
use Test::Requires qw{
    Template
};

use FindBin;
use lib "$FindBin::Bin/../lib";
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my @params = my %params = (
    last_hotel        => 'Marriot',
    last_street       => 'Via Zapata',
    last_maiden       => 'Cook',
    first_middle_name => 'Curtis',
    first_pet         => 'Sasha',
    first_car         => 'Wrangler',
    appstate          => 'complete',
);

my $handler = builder {
    enable "Magpie",
        context  => {},
        pipeline => [
        'Magpie::Pipeline::TT2::Base',
        'Magpie::Pipeline::TT2::Output' =>
            { template_path => './t/htdocs/templates/moviename' }
        ];
};

test_psgi
    app    => $handler,
    client => sub {
    my $cb = shift;
    {
        my $res = $cb->( GET "http://localhost/" );
        like $res->content, qr/fabulous/;
        like $res->content, qr/input/;
        like $res->content, qr/submit/;
    }
    {
        my $res
            = $cb->( POST "http://localhost/?appstate=complete", \%params );
        my $body = $res->content;
        like $body, qr/Congratulations/;
        foreach my $key ( keys(%params) ) {
            next if $key eq 'appstate';
            like $body, qr/$params{$key}/;
        }
    }

    };

done_testing;
