use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Requires qw{
    DBIx::Class
    DBD::SQLite
};

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use Bread::Board;
use HTTP::Request::Common;
use Magpie::DBIC::Schema;

my %user = (
    name   => 'ubu',
    status => 'dubious at best',
);

my $assets = container '' => as {
    service 'somevar'   => 'some value';
    service 'dbic_schema' => (
        lifecycle => 'Singleton',
        block     => sub {
            my $s = shift;
            my $schema = Magpie::DBIC::Schema->connect( "dbi:SQLite::memory:", create => 1, );
            $schema->deploy();
            return $schema;
        },
    );
};

my $handler = builder {
    enable "Magpie",
        assets   => $assets,
        pipeline => [
        machine {
            match qr|/users| => [
                'Magpie::Resource::DBIC' => {
                    result_class => 'Magpie::DBIC::Schema::Result::User'
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
    my $url = "http://localhost/users/";
    my $created_url = undef;
    {
        my $res = $cb->( POST $url => \%user );
        #warn "RES: " . $res->content;

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
    {
        if ($created_url) {
            my $updated_user = { status => 'still dubious', name => 'roy' };
            my $res = $cb->( POST $created_url, $updated_user);
            is $res->code, 204, "correct POST update response.";

            # refetch to make sure the update stuck
            my $res2 = $cb->( GET $created_url);
            is $res2->code, 200, "correct GET response.";
            like $res2->content, qr|roy|, 'Updated JSON serialized';
            #warn $res2->content;
        }
        else {
         fail "GET to follow-on URL failed."
        }
    }
    {
        if ($created_url) {
            my $res = $cb->(HTTP::Request::Common::DELETE $created_url);
            is $res->code, 204, "correct DELETE response.";

            my $res2 = $cb->( GET $created_url);
            is $res2->code, 404, "correct GET response for deleted entity.";
            #warn $res2->content;

        }

    }
    };

ok(1);
done_testing;
