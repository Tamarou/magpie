package Magpie::Breadboard;
use Moose;
use Bread::Board;

extends 'Bread::Board::Container';

has '+name' => ( default => 'Application' );

has resources => (
    is          =>  'rw',
    isa         =>  'Bread::Board::Container',
    lazy_build  => 1,
    #init_arg    => 'Resources',
);

sub _build_resources {
    return Bread::Board::Container->new( name => 'Resources' );
}

sub BUILD {
    my $self = shift;
    container $self => as { container 'Resources' => as{ $self->resources }};
}

1;
