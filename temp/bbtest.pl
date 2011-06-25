use Test::More;
use FindBin;
use Data::Dumper::Concise;
use lib qw( $FindBin::Bin/lib $FindBin::Bin/../lib );

{
package MyApp::Wibble;
use Moose;
use FindBin;
use Bread::Board::Declare;
use Data::Dumper::Concise;
use lib qw( $FindBin::Bin/lib $FindBin::Bin/../lib );
use Module::Find ();

has wev => (
    is => 'rw',
    isa => 'Bread::Board::Container',
);

sub build {
    my $self = shift;
    my $package = my $base = $self->meta->name;
    my $dir = "$FindBin::Bin/lib";

    if ( $package =~ m|^(.*)\::| ) {
        $base = $1;
    }

    my $app_container = Bread::Board::Container->new( name => 'Application' );
    Module::Find::setmoduledirs($dir);
    foreach my $type qw( Resource Transformer ) {
        my $plural = lc( $type ) . 's';
        my $namespace = "${base}::$type";
        warn "$dir $package $base $namespace $plural\n";
        my $subcontainer = Bread::Board::Container->new( name => $type );


        my @feh = Module::Find::findallmod( "${base}::$type" );
        warn "listie: " . Dumper(\@feh);

        $subcontainer->add_service(

        );

        $app_container->add_sub_container( $subcontainer );

#         my $plug = Module::Pluggable::Object->new( search_path => [$namespace] );
#
#         my @wev = $plug->plugins();
#         warn Dumper( \@wev );
    }

    $self->wev( $app_container );
}
}


my $app = MyApp::Wibble->new;

ok( $app );

$app->build();

my @res = $app->wev;

warn "res: " . Dumper( \@res );
done_testing;
#build();

