package Clone::Closure;

use 5.006001;

use strict;
use Carp;

use base 'Exporter';
our @EXPORT_OK = qw( clone );

our $VERSION = '0.04_01';

use XSLoader;
XSLoader::load __PACKAGE__, $VERSION;

$VERSION = eval $VERSION;

1;
__END__

=head1 NAME

Clone::Closure - A clone that knows how to clone closures

=head1 SYNOPSIS

    use Clone::Closure qw/clone/;

    my $total;

    sub count {
        my $count;
        return sub { $count++, $total++ };
    }

    my $foo = count;
    my $bar = clone $foo;

    # $bar has its own copy of $count, but shares $total 
    # with $foo.

=head1 DESCRIPTION

This module provides a C<clone> method which makes recursive
copies of nested hash, array, scalar and reference types, 
including tied variables, objects, and closures.

C<clone> takes a scalar argument. To duplicate arrays or hashes, pass
them in by reference, e.g.
    
    my $copy = clone \@array;

    # or

    my %copy = %{ clone \%hash };

=head2 Values which are not cloned

Sub (except for L</Closures>), glob, format and IO refs are simply
duplicated, not cloned.

=head2 Closures

Closures are cloned, unlike with L<Clone|Clone>. Closed-over lexicals
will be cloned if they were originally declared in a scope that could be
run more than once, and shared otherwise. 

That is, in the example in the
L</SYNOPSIS>, $count is cloned as it is scoped to &count, which can run
many times with different $count variables; but $total is shared as it
is file-scoped, so there will only ever be one copy. 

Generally speaking, C<clone> will produce what might have been another
copy of the closure, generated by the same means. However, see L</BUGS>
below.

=head2 Magic

The following types of magic are preserved:

=over 4

=item *

shared variables

Cloning a shared variable creates a new shared variable, but it is not
shared with any other threads yet. That is, the clone is only visible in
this thread and any threads you create later.

=item *

tied variables

The tied object will also be cloned.

=item *

C<qr//> compiled regexes

=item *

tainted values

Cloning a tainted value produces a tainted copy.

=item *

globs

Globs are not cloned. Cloning a glob returns the original glob.

=item *

weakrefs

Beware cloning weakrefs: cloning a reference also clones the object it
refers to, and if there are no strong refs to this new object it will
self-destruct before C<clone> returns. For example,

    my $sv  = 5;
    my $ref = \$sv;
    weaken $ref;
    my $clone = clone $ref;

will result in $clone being C<undef>, as the new clone of $sv has no
(strong) referents. As weakrefs are normally used to break loops in
self-referential structures, this should not happen often.

=item *

custom magic (C<U>, C<u>, and C<~> magics)

These will be cloned, and if the magic has a C<mg_obj> that will be
cloned too. This is not necessarily the right thing to do, depending on
what the custom magic is being used for.

=item *

Boyer-Moore fast string search

=item *

vstring magic

=item *

UTF8 cache magic

These types of magic are not visible from Perl-space, and are used by
perl to optimize certain operations.

=back

All other types of magic are dropped when cloning, so for example

    my $env = clone \%ENV;

will produce a normal hashref containing a copy of the environment.

=head1 BUGS

=head2 Loops

Loops are currently not correctly recognized as 'scopes that may run
more than once'. That is, given

    my @subs;

    for my $i (1..10) {
        push @subs, sub { $i };
    }

a clone of $subs[0] will B<share> $i, which is probably not what you
wanted. One possible workaround is to generate the closure in a sub,
with its own lexical; for example

    my @subs;

    sub make_closure {
        # this is important, so we get a new lexical
        my $i = shift;
        
        return sub { $i };
    }

    for my $i (1..10) {
        push @subs, make_closure $i;
    }

A clone of $subs[0] will now have its own copy of $i.

Note that this behaviour B<will> change in a future release;
unfortunately, I can't provide a warning (as I haven't worked out how to
detect loops...).

=head2 5.6 and C<eval I<STRING>>

Under 5.6, lexicals which are closed over by C<eval I<STRING>> will
always be cloned, never shared. That is, given

    my $x;
    my $sub = eval 'sub { $x }';

a clone of $sub will have its own copy of $x, which is incorrect.

=head1 TODO

=over 4

=item *

Fix the loop bug.

=item *

Do something sensible with fieldhashes.

=item *

Provide a means to specify what is cloned and what copied.

=back

=head1 AUTHOR

This module is based on Clone v0.23 by Ray Finch, <rdf@cpan.org>.

Clone is copyright 2001 Ray Finch.

This module is copyright 2007 Ben Morrow, <ben@morrow.me.uk>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Clone|Clone>, L<Storable|Storable>.

=cut
