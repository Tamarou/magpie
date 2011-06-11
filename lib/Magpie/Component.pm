package Magpie::Component;
use Moose;
with qw(Magpie::Event);
use Magpie::Constants;

use Data::Dumper::Concise;


sub init_symbols {
    my ($self, $context) = @_;

    my @events = ();
    my %processed_events = ();

    my @self_and_ancestors = $self->meta->linearized_isa;

    # need the full list to cover overridden methods not registered (via register_events()) in component subclasses.

    foreach my $obj ( @self_and_ancestors ) {
        next unless $obj->can('registered_events');
        push @events, $obj->registered_events;
    }


    foreach my $obj ( $self->meta->linearized_isa ) {
        for (my $i = 0; $i < scalar @events; $i++ ) {

            next if ref( $events[$i]) eq 'CODE';
            next if defined $processed_events{$events[$i]};

            if ( ref( $events[ $i + 1]) eq 'CODE' ) {
                $self->add_symbol_handler( $events[$i] => $events[ $i + 1] );
                $processed_events{$events[$i]}++;
            }
            elsif ( my $ref = $obj->can($events[$i]) ) {
                $self->add_symbol_handler( $events[$i] => $ref );
                $processed_events{$events[$i]}++;
            }
        }
    }
}

no Moose;
1;
__END__