use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Middleware::Magpie;

my $context = {
    is              => 'everything',
    actually        => 'matters',
    is_frequently   => [qw(ignored misunderstood)],
};

my $handler = builder {
    enable "SimpleLogger", level => 'debug';
    enable "Magpie", context => $context, debug => 1, matcher_class => 'Core::StaticMatcher';

};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/");
            like $res->content, qr/_curlyfoo_RIGHT_curlyfoo_WRONG/;
        }
    };

done_testing();