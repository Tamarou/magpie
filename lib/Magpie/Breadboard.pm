package Magpie::Breadboard;
use Moose;
use Bread::Board;
use Bread::Board::Dumper;
extends 'Bread::Board::Container';

has '+name' => ( default => 'Application' );

sub BUILD {
    my $self = shift;
    container $self => as {
        container 'Assets' => as {};
        container 'MagpieInternal' => as {};
    };
}

sub assets {
    my $self = shift;
    if ( my $new_container = shift ) {
        delete $self->sub_containers->{'Assets'};
        $new_container->name('Assets');
        $self->add_sub_container( $new_container );
    }
    return $self->get_sub_container('Assets');
}

sub add_asset {
    my $self = shift;
    my $thing = shift;
    warn "WTF?????";
    my $assets = $self->get_sub_container('Assets');

    warn "internal " . Bread::Board::Dumper->new->dump( $assets );
    if ( $thing->isa('Bread::Board::Container') ||
         $thing->isa('Bread::Board::Container::Parameterized') ) {
        $assets->add_sub_container( $thing );
    }
    elsif ( $thing->isa('Bread::Board::Service') ) {
        $assets->add_service( $thing );
    }
    else {
        confess "add_asset requires a type => typmap pair, service, or container."
    }
}

sub resolve_asset {
    return shift->assets->resolve( @_ );
}

1;
