package Magpie::Machine;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::File;

#ABSTRACT: Event Class For Creating Magpie Pipelines

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject|Undef',
    coerce      => 1,
    #default     => sub { Magpie::Resource::File->new }
);

sub has_resource { defined shift->resource ? 1 : 0 }


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

# SEEALSO: Magpie

1;
