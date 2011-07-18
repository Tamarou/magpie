use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Magpie;
use HTTP::Request::Common;

my $named_handler = builder {
    enable "Magpie", pipeline => [qw( Magpie::Pipeline::Error::Named  Magpie::Pipeline::Moe Magpie::Pipeline::Curly )];
};

test_psgi
    app    => $named_handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 418;
    };

my $numeric_handler = builder {
    enable "Magpie", pipeline => [qw( Magpie::Pipeline::Error::Numeric  Magpie::Pipeline::Moe Magpie::Pipeline::Curly )];
};

test_psgi
    app    => $numeric_handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 418;
    };

my $hashref_handler = builder {
    enable "Magpie", pipeline => [qw( Magpie::Pipeline::Error::Hashref  Magpie::Pipeline::Moe Magpie::Pipeline::Curly )];
};

test_psgi
    app    => $hashref_handler,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 418;
    };

done_testing;
