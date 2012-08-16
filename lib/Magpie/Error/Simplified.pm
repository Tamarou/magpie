package Magpie::Error::Simplified;
use Moose::Role;

# A simple role to work around HTTP::Throwable's over-helpfulness

sub body { shift->reason }

sub body_headers {
    my ($self, $body) = @_;
    return [
        'Content-Length' => length $body,
    ];
}

sub as_string { shift->body }

1;