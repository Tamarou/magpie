use Test::More;
use Plack::Test;
use Plack::Request;
use Data::Dumper::Concise;
use FindBin;
use lib "$FindBin::Bin/lib";
use_ok('Magpie::Machine');

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
        my $req = HTTP::Request->new(GET => "http://localhost/");
        my $res = $cb->($req);
        like $res->content, qr/_moebaz__moebar__larryfoo__larrybar__curlyfoo_/;
    };

done_testing();