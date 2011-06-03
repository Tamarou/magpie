package Magpie::Common;
use Moose::Role;
with qw(MooseX::Log::Log4perl);

use Log::Log4perl qw(:easy);
use Config::Path;
use Data::Dumper;

BEGIN {
    Log::Log4perl->easy_init();
}

1;

