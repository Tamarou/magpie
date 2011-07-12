package Magpie::Resource::Kioku;
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;
use Plack::App::File;

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my $r = Plack::App::File->new->call($self->request->env);

    unless ( $r->[0] == 200 ) {
        $self->set_error({
            status_code => $r->[0],
            additional_headers => $r->[1],
            reason => join "\n", @{$r->[2]},
        });
    }

    $self->plack_response( Plack::Response->new(@$r) );

    return OK;
}


1;