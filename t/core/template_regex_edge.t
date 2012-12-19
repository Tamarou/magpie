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
            match_template '/api/(project|user)/?(?!./){object_id}' => ['Magpie::Pipeline::PathMadness'];
        },
    ];
};

test_psgi
    app    => $handler,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET "http://localhost/api/project/1234567");
            like $res->content, qr|pathmadness__object_id::1234567_|;
        }
        {
            my $res = $cb->(GET "http://localhost/api/user/655321");
            like $res->content, qr|pathmadness__object_id::655321_|;
        }
        {
            my $res = $cb->(GET "http://localhost/api/user");
            like $res->content, qr|pathmadness__object_id::_|;
        }
        {
            my $res = $cb->(GET "http://localhost/api/project/1234567/some/endpoint");
            like $res->content, qr|pathmadness__object_id::1234567_|;
        }
    };

done_testing();