package Magpie::Machine;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;



#-------------------------------------------------------------------------------
# pipline( @list_of_class_names )
# This loads the list of Event classes that will constitue the app's
# program flow.
#-------------------------------------------------------------------------------
sub pipeline {
    my $self    = shift;
    my @handlers = @_;
    my @realhandlers = ();

    foreach my $handler ( @handlers ) {
        #warn "UNE PIPE $handler \n";
        # remember that this method can accept other pipelines
        # as elements, not just classnames.
        if ( my $ref = ref($handler) ) {
            my $handler_name =  $ref;
            push @realhandlers, $handler_name;
            $self->register_handler($handler_name => $handler);
        }
        else {
            push @realhandlers, $handler;
        }
    }

    $self->handlers(\@realhandlers);
}

1;