package MyApp::Resource::One;
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;

has simple_arg => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        default => 'Teh Schnoper',
);

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my $p = __PACKAGE__;
    warn "$p GET called. simple arg is " . $self->simple_arg . "\n";
}


1;