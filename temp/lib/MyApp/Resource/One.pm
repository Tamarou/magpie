package MyApp::Resource::One;
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;
use Plack::App::File;

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my $p = __PACKAGE__;
    warn "$p GET called\n";
}


1;