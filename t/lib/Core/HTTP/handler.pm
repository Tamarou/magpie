package http::handler;
use SAWA::Machine;
use mod_perl;
use constant MP2 => $mod_perl::VERSION >= 1.99;
BEGIN {
        if (MP2) {
                require Apache::Response;
                require Apache::Const;   
        } else {
                require Apache::Constants;
                require Apache::Request;
        }
}

sub handler {
    my $r = shift;
    my $app;
    if (MP1) {
        my $q = Apache::Request->instance( $r );
        $app = SAWA::Machine->new({ -query => $q });
    }
    else {
        $app = SAWA::Machine->new({ -query => $r });
    }

    $app->pipeline( qw(
        http::Base
        basic::Output
    ) );
    return $app->run({});
    #return MP2 ? Apache::OK : Apache::Constants::OK;
}

1;
