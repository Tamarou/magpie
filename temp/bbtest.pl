use Test::More;
use FindBin;
use Data::Dumper::Concise;
use lib "$FindBin::Bin/lib";

{
package MyApp::Wibble;
use Moose;
use FindBin;
use Bread::Board::Declare;
use Data::Dumper::Concise;
use lib "$FindBin::Bin/lib";
use Module::Find ();

has config => (
    is => 'rw',
    isa => 'Bread::Board::Container',
    #required => 1,
);


sub BUILD {
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

        my @packages = Module::Find::findallmod( $namespace );
        warn "listie: " . Dumper(\@packages);

        foreach my $package ( @packages ) {
            my $short_name = $package;
            $short_name =~ s/$namespace:://;
            $subcontainer->add_service(
                Bread::Board::ConstructorInjection->new(
                    class => $package,
                    name => $short_name,
                    parameters => {
                        simple_arg => { isa => 'Str' }
                    },
                    lifecycle => 'Singleton',
                )
            );
        }

        $app_container->add_sub_container( $subcontainer );

#         my $plug = Module::Pluggable::Object->new( search_path => [$namespace] );
#
#         my @wev = $plug->plugins();
#         warn Dumper( \@wev );
    }

    $self->config( $app_container );
}
}


my $app = MyApp::Wibble->new;

ok( $app );

my $c = $app->config;

warn "res: " . Dumper( $c );

#my $wtf = $c->resolve( service => 'Resource/One');

my $wtf = $c->fetch('Resource/One')->get( simple_arg => 'Teh Awesome' );

ok( $wtf );

warn Dumper( $wtf );

$wtf->GET;

my $other = $c->resolve( service => 'Resource/One');

ok( $other );

$wtf->simple_arg('Some Shit');

$other->GET;

my $third = $c->fetch('Resource/One')->get( simple_arg => 'Mixup' );

ok( $third );

$third->GET;
done_testing;


