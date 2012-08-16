package Magpie::Breadboard;
use Moose;

# ABSTRACT: Bread::Board Container For Pipeline Assets

use Bread::Board;
use Bread::Board::Dumper;

extends 'Bread::Board::Container';

has '+name' => ( default => 'Application' );

sub BUILD {
    my $self = shift;
    container $self => as {
        container 'Assets' => as {};
        container 'MagpieInternal' => as {
            service 'default_resource' => (
                lifecycle => 'Singleton',
                block => sub {
                    my $s = shift;
                    Magpie::Resource::Abstract->new;
                }
            );
            service 'symbol_table' => (
                lifecycle => 'Singleton',
                block => sub {
                    my $s = shift;
                    Magpie::SymbolTable->new;
                }
            );

        };
    };
}

sub internal_assets {
    return shift->get_sub_container('MagpieInternal');
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

    if ( blessed $thing ) {
        if ( $thing->isa('Bread::Board::Container') || $thing->isa('Bread::Board::Container::Parmeterized')) {
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

sub resolve_internal_asset {
    return shift->internal_assets->resolve( @_ );
}

sub resolve_asset {
    return shift->assets->resolve( @_ );
}

# SEEALSO: Magpie, Bread::Board

1;
