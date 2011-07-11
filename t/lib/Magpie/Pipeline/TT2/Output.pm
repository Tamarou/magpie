package Magpie::Pipeline::TT2::Output;
use Moose;
extends qw(Magpie::Transformer::TT2);
use Magpie::Constants;

sub get_template {
    my $self = shift;
    my $ctxt = shift;
    $self->template_file( $ctxt->{template} );
    return OK;
}

sub get_tt_vars {
    my $self = shift;
    my $ctxt = shift;
    for ( $self->request->param ) {
        $ctxt->{$_} = $self->request->param($_);
    }
    $self->tt_vars($ctxt);
    return OK;
}


1;
