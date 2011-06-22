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

    my @handlers = ();
    my @handler_args = ();

    my @pairs = ();
    for (my $i = 0; $i < scalar @args; $i++ ) {
        next if ref( $args[$i] ) eq 'HASH';
        my $handler_args = {};
        if ( ref( $args[$i + 1 ]) eq 'HASH' ) {
            $handler_args = $args[$i + 1 ];
        }
        #warn "UNE PIPE $handler \n";
        # remember that this method can accept other pipelines
        # as elements, not just classnames.
        if ( my $ref = ref($args[$i]) ) {
            my $handler_name =  $ref;
            push @handlers, $handler_name;
            $self->register_handler($handler_name => $args[$i]);
        }
        else {
            push @handlers, $args[$i];
        }

        push @handler_args, $handler_args;
    }

    $self->handlers(\@handlers);
    $self->handler_args(\@handler_args);
}

1;