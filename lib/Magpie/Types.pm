package Magpie::Types;
# ABSTRACT: Common Magpie Type Constraints
use Moose::Role;
use HTTP::Throwable::Factory;
use Moose::Util::TypeConstraints;

my %http_lookup = (
    300 => 'MultipleChoices',
    301 => 'MovedPermanently',
    302 => 'Found',
    303 => 'SeeOther',
    304 => 'NotModified',
    305 => 'UseProxy',
    307 => 'TemporaryRedirect',
    400 => 'BadRequest',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'NotFound',
    405 => 'MethodNotAllowed',
    406 => 'NotAcceptable',
    407 => 'ProxyAuthenticationRequired',
    408 => 'RequestTimeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'LengthRequired',
    412 => 'PreconditionFailed',
    413 => 'RequestEntityTooLarge',
    414 => 'RequestURITooLong',
    415 => 'UnsupportedMediaType',
    416 => 'RequestedRangeNotSatisfiable',
    417 => 'ExpectationFailed',
    418 => 'ImATeapot',
    500 => 'InternalServerError',
    501 => 'NotImplemented',
    502 => 'BadGateway,',
    503 => 'ServiceUnavailable',
    504 => 'GatewayTimeout',
    505 => 'HTTPVersionNotSupported',
);

subtype 'SmartHTTPError' => as 'Maybe[Object]';

coerce 'SmartHTTPError'
    => from 'HashRef'
        => via { HTTP::Throwable::Factory->new_exception($_) },
    => from 'Int'
        => via { my $name = code_lookup($_); return HTTP::Throwable::Factory->new_exception( $name => {}) },
    => from 'Str'
        => via { HTTP::Throwable::Factory->new_exception($_ => {}) },
;

sub code_lookup {
    my $numeric = shift;
    return defined( $http_lookup{$numeric} ) ? $http_lookup{$numeric} : $http_lookup{'500'};
}

subtype 'MagpieResourceObject' => as 'Maybe[Object]';

coerce 'MagpieResourceObject'
    => from 'HashRef'
        => via {
            my $args = $_;
            my $class = delete $args->{class};
            Class::MOP::load_class( $class );
            $class->new( $args );
        },
    => from 'Str'
        => via {
            my $class = shift;
            Class::MOP::load_class( $class );
            $class->new;
        },
;

# SEEALSO: Magpie

1;
