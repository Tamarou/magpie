package Magpie::Dispatcher::RequestMethod;
#ABSTRACT: INCOMPLETE - Placeholder for future Dispatcher Role
use Moose::Role;
use Magpie::Constants;
sub events { (qw(method_not_allowed), HTTP_METHODS) };

sub load_queue {
    my $self   = shift;
    my $method = $self->plack_request->method;
    if ( scalar grep { $_ eq $method } HTTP_METHODS ) {
        return $method;
    }
    return 'method_not_allowed';
}

1;

__END__
=pod

#SEEALSO: Magpie
