package Magpie::Plugin::Resource::Cache;
use Moose::Role;
use Magpie::Constants;
use Data::Dumper::Concise;

requires qw(mtime _build_cache);

has cache => (
    is          => 'ro',
    lazy_build  => 1,
);

around 'GET' => sub {
    my $orig = shift;
    my $self = shift;
    my $mtime = $self->mtime;
    my $uri = $self->request->uri->as_string;

    if ( $mtime && $mtime > 0 ) {
        my $data = $self->cache->get($uri);
        if ($data && defined $data->{resource} && defined defined $data->{resource}->{mtime} && $mtime == $data->{resource}->{mtime}) {
            my $content = $data->{content};
            $self->data($content);
            return DONE;
        }
        else {
            # actual content will be added at the end of the pipeline process
            my $data = { content => '', resource => { mtime => $mtime,}};
            $self->cache->set($uri, $data);
            $self->parent_handler->add_handler('Magpie::Component::ContentCache');
        }
    }

    return $self->$orig(@_);
};

after [qw(add_dependency delete_dependency)] => sub {
    my $self = shift;
    my $uri = $self->request->uri->as_string;
    my $data = $self->cache->get($uri);

    unless ( $data ) {
        $data = {};
    }

    $data->{resource}->{dependencies} = $self->dependencies;

    $self->cache->set($uri, $data);
};

1;
