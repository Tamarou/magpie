package Magpie::Breadboard;
use Moose;
use Bread::Board;
use Bread::Board::Dumper;
use Data::Dumper::Concise;
use Scalar::Util qw(blessed);
extends 'Bread::Board::Container';

has '+name' => ( default => 'Application' );

sub BUILD {
    my $self = shift;
    warn "BUILD by " . join ', ', caller(0);
    container $self => as {
        container 'Assets' => as {};
        container 'MagpieInternal' => as {};
    };
    warn Dumper( $self );
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

    my $assets = $self->get_sub_container('Assets');

    #warn "internal " . Bread::Board::Dumper->new->dump( $assets );
    if ( blessed $thing ) {
        if ( $thing->does('Bread::Board::Container') ) {
            $assets->add_sub_container( $thing );
        }
        elsif ( $thing->does('Bread::Board::Service') ) {
            $assets->add_service( $thing );
        }
        else {
            confess "add_asset requires a type => typemap pair, service, or container."
        }
    }
    elsif ($_[0] and blessed($_[0]) and $_[0]->isa('Bread::Board::Typemap')){
        $assets->add_type_mapping( $thing => $_[0] );
    }
    else {

    }
}

sub resolve_asset {
    return shift->assets->resolve( @_ );
}

1;
