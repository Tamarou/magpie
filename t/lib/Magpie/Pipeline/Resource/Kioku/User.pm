package Magpie::Pipeline::Resource::Kioku::User;
use Moose;

with qw(KiokuX::User);
use KiokuX::User::Util qw(crypt_password);

around BUILDARGS => sub {
    my ( $next, $self ) = shift, shift;
    my $args = $self->$next(@_);
    if ( exists $args->{password} && !blessed( $args->{password} ) ) {
        $args->{password} = crypt_password( $args->{password} );
    }
    return $args;
};

has status => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

1;
