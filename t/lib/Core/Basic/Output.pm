package Core::Basic::Output;
use Moose;
use Magpie::Constants;
extends 'Magpie::Transformer';

my @events = qw( get_content );

__PACKAGE__->register_events( @events );

sub load_queue { @events }

sub get_content {
    my $self = shift;
    my $ctxt = shift;
    my $out = '<html><body>' . $ctxt->{content} . '</body></html>';
    $self->resource->data($out);
    return OK;
}

1;
