use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;
use FindBin;
use lib "$FindBin::Bin/lib";
use Magpie::Machine;

test_psgi
    app => sub {
        my $env = shift;
        my $m = Magpie::Machine->new;
        $m->pipeline(qw( Magpie::Pipeline::Moe Magpie::Pipeline::Larry Magpie::Pipeline::Curly));
        ok( $m );
        $m->plack_request( Plack::Request->new($env) );
        $m->run({});
        return $m->plack_response->finalize;
    },
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/");
        like $res->content, qr/_moebaz__moebar__larryfoo__larrybar__curlyfoo_/;
    };

done_testing();
