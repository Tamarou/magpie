package Magpie::Component;
use Moose;
with qw(Magpie::Event);
use Magpie::Constants;

use Data::Dumper::Concise;


sub init_symbols {
    my ($self, $context) = @_;
    my @events = $self->registered_events;

    for (my $i = 0; $i < scalar @events; $i++ ) {
        next if ref( $events[$i]) eq 'CODE';
        if ( ref( $events[ $i + 1]) eq 'CODE' ) {
            $self->add_symbol_handler( $events[$i] => $events[ $i + 1] );
        }
        elsif ( my $ref = $self->can($events[$i]) ) {
            $self->add_symbol_handler( $events[$i] => $ref );
        }
        else {
            warn "Unknown symbol '$events[$i]': could not be registered."
        }
    }
}

no Moose;
1;
__END__