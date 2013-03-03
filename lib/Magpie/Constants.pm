package Magpie::Constants;

# ABSTRACT: Common Handler Control Constants;

use constant {
    OK            => 100,
    DECLINED      => 199,
    DONE          => 299,
    OUTPUT        => 300,
    SERVER_ERROR  => 500,
    HANDLER_ERROR => 501,
    QUEUE_ERROR   => 502,
};

use Sub::Exporter -setup => {
    exports => [
        qw(OK DECLINED DONE OUTPUT SERVER_ERROR HANDLER_ERROR QUEUE_ERROR),
        HTTP_METHODS => sub {
            my ( $class, $name, $arg, $col ) = @_;

            sub () {
                qw(GET POST PUT DELETE HEAD OPTIONS TRACE PATCH CONNECT),
                    @{ $arg{extra_http_methods} // [] },
                    @{ $col{extra_http_methods} // [] };
            };
        },
    ],
    groups => [
        default => [
            qw(OK DECLINED DONE OUTPUT SERVER_ERROR HANDLER_ERROR QUEUE_ERROR HTTP_METHODS)
        ],
    ],
    collectors => [qw(extra_http_methods)]
};

# SEEALSO: Magpie, Magpie::Component, Magpie::Event

1;
__END__
