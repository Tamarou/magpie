package Magpie::Transformer::TT2;
# ABSTRACT: Template Toolkit Transformer Component

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use Template;
use MooseX::Types::Path::Class;
use Try::Tiny;

__PACKAGE__->register_events( qw( get_tt_conf get_tt_vars get_template get_transformer transform));

sub load_queue { return qw( get_tt_conf get_tt_vars get_template get_transformer transform ) }

has tt_conf => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

has tt_vars => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { {} },
);

has template_file => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    init_arg    => 'template',
    coerce      => 1,
);

has template_path => (
    is          => 'ro',
    isa         => 'Path::Class::Dir',
    coerce      => 1,
    required    => 1,
);

has transformer => (
    is          => 'rw',
    isa         => 'Template',
);

sub get_tt_conf  { OK; }
sub get_tt_vars  { OK; }
sub get_template { OK; }

sub get_transformer {
    my $self = shift;
    my $conf = $self->tt_conf;
    my $template_path = $self->template_path->stringify;
    my $tt_obj = Template->new(
        { %$conf, INCLUDE_PATH => $template_path }
    );
    $self->transformer($tt_obj);
    return OK;
}

use Encode;
sub transform {
    my ($self, $ctxt) = @_;
    my $tt = $self->transformer;
    my $template = $self->template_file->stringify;
    my %tt_vars = %{ $self->tt_vars };
    my $output;

    $tt_vars{magpie} = $self;

    try {
        $tt->process( $template, \%tt_vars, \$output ) || die $tt->error
    }
    catch {
        my $error = "Error processing template: $_";
        warn "$error\n";
        $self->set_error({ status_code => 500, reason => $error });

    };

    return OK if $self->has_error;

    $self->resource->data( encode('UTF-8', $output) );

    return OK;
}

# SEEALSO: Magpie

1;