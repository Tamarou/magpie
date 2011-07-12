package Magpie::Machine;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::File;

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    coerce      => 1,
    default     => sub { Magpie::Resource::File->new }
);

#-------------------------------------------------------------------------------
# pipline( @list_of_class_names )
# This loads the list of Event classes that will constitue the app's
# program flow.
#-------------------------------------------------------------------------------
sub pipeline {
    my $self    = shift;
    my @args = @_;
    my @handlers = $self->_make_tuples( @args );
    $self->handlers(\@handlers);
}

1;