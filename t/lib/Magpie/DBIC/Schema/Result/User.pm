package Magpie::DBIC::Schema::Result::User;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table('users');

__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size => 50,
    },
    status => {
        data_type => 'varchar',
        size => 50,
    },
);

__PACKAGE__->set_primary_key('id');

sub TO_JSON {
    my $self = shift;
    return {
        name => $self->name,
        status => $self->status,
    };
}

1;
