package Magpie::Transformer::JSON;
use Moose;

# ABSTRACT: JSON Ouput Transformer

extends 'Magpie::Transformer';
use Scalar::Util qw(blessed);
use Magpie::Constants;
use JSON;

__PACKAGE__->register_events(qw(transform));

sub load_queue { return qw(transform) }

sub transform {
    my $self = shift;

    return DECLINED if $self->resource->isa('Magpie::Resource::Abstract');
    if ( $self->resource->has_data ) {

        my $data        = $self->resource->data;
        my $json_string = undef;
        if ( blessed $data) {
            if ($data->does('Data::Stream::Bulk') ) {
                my @objects = ();
                while ( my $block = $data->next ) {
                    foreach my $object (@$block) {
                        my $data
                            = $object->can('pack') ? $object->pack : {%$object};
                        push @objects, JSON::encode_json($data);
                    }
                }
                $json_string = '[' . ( join ', ', @objects ) . ']';
            }
            else {
                $json_string = JSON->new->utf8->allow_blessed->convert_blessed->encode($data);
            }
        }
        else {
            $json_string
                = JSON::encode_json($data);
        }
        $self->response->content_type('application/json');
        $self->response->content_length( length($json_string) );
        $self->resource->data($json_string);
    }

    return OK;
}

1;
__END__
