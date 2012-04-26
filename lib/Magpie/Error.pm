package Magpie::Error;
use Moose;
extends 'HTTP::Throwable::Factory';

sub roles_for_no_ident {
    my ($self, $ident) = @_;
    return qw(
        HTTP::Throwable::Role::Generic
    );
}

sub extra_roles {
    return qw(
        Magpie::Error::Simplified
    );
}


1;