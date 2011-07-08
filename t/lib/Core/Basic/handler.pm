package basic::handler;
use SAWA::Machine;
use basic::Base;
use mod_perl;
use constant MP2 => $mod_perl::VERSION >= 1.99;
BEGIN {
        if (MP2) {
                require Apache::Response;
                require Apache::Const;
        } else {
                require Apache::Constants;
        }
}

sub handler {
    my $r = shift;
    my $app = SAWA::Machine->new();
    $app->state_param('fn');
    $app->pipeline(
        basic::Base->new(),
        'basic::Output'
    );
    return $app->run({});
    #return MP2 ? Apache::OK : Apache::Constants::OK;;
}

1;
