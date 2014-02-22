package Magpie::Transformer::Input::Stripe;
use Moose;
extends qw(Magpie::Transformer);
use Magpie::Constants;
use Net::Stripe;

__PACKAGE__->register_events(qw(transform));
sub load_queue { return qw(transform) }

has stripe => (
    isa     => 'Net::Stripe',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_stripe'

);

sub _build_stripe {
    my $self = shift;
    try { 
        $self->resolve_asset(service => 'stripe');
    } catch { 
        try { 
            my $api_key = $self->resolve_asset($api_key);
            Net::Stripe->new( api_key => $api_key);
        }
        catch { 
            $self->set_error({status_code => 500, reason => "Couldn't find stripe service or API key");
        }
    };
}

sub transform {
    my $self = shift;
    my $ctxt = shift;
    my $data = $self->resource->data // $ctxt->{data};
    return SERVER_ERROR unless $data;
    unless (defined $data->{stripeToken}) {
        $self->set_error( { status_code => 402, reason => 'No stripeToken found'} );
        return DONE;
    try {
        my $desc = "Payment for $$data{resourceName}: $$data{student}{name}";
        $self->stripe->post_charge(
            amount      => $data->{amount},
            currency    => 'usd',
            card        => $data->{stripeToken},
            description => $desc,
        );
        return OK;
    }
    catch {
        $self->set_error( { status_code => 400, reason => $_ } );
        return DECLINED;
    };

}

1;
__END__
