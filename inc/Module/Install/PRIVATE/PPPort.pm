#line 1
package Module::Install::PRIVATE::PPPort;

use strict;
use warnings;

use Module::Install::Base;

our @ISA = 'Module::Install::Base';

sub ppport {
    my $self = shift;
    
    $self->admin->ppport;

    $self->postamble(<<MM);
distclean ::
\t\$(RM_F) ppport.h

MM

    1;
}

1;
