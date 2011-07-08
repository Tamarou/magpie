package htmltemplate::Output;
use strict;
use warnings;
use SAWA::Constants;
use base qw(SAWA::Output::HTMLTemplate);

sub get_template {
    my $self = shift;
    my $ctxt = shift;

    # this is more complest than it usually would be
    # due to the fact that the test dir may be installed 
    # in any dir
    my $style_path = $self->static_path . '/templates/moviename/';

#     if ($ENV{MOD_PERL}) {
#         $style_path = $self->query->r->document_root;
#         $style_path .= '/templates/moviename/';
#     }
#     else {
#         require Cwd;
#         $style_path = Cwd::abs_path('../htdocs/templates/moviename');
#         $style_path .= '/';
#     }

    $self->template_path( $style_path );
    $self->template( $ctxt->{template} );
    return OK;
}
    
sub get_template_vars { 
    my $self = shift;
    my $ctxt = shift;
    for ( $self->query->param ) {
        $ctxt->{$_} = $self->query->param($_);
    }
    $self->template_vars($ctxt);    
    return OK;
}

sub get_template_conf { 
    my $self = shift;
    $self->template_conf({
        die_on_bad_params => 0
    });    
    return OK;
}

1;
