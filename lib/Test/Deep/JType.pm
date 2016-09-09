use strict;
use warnings;
package Test::Deep::JType;
# ABSTRACT: Test::Deep helpers for JSON::Typist data

use Test::Deep 1.123 (); # for LeafWrapper and obj~~re diagnostics

use Exporter 'import';
our @EXPORT = qw( jcmp_deeply jstr jnum jbool jtrue jfalse );

=head1 OVERVIEW

L<Test::Deep> is a very useful library for testing data structures.
Test::Deep::JType extends it with routines for testing
L<JSON::Typist>-annotated data.

By default, Test::Deep's C<cmp_deeply> will interpret plain numbers and strings
as shorthand for C<shallow(...)> tests, meaning that the corresponding input
data will also need to be a plain number or string.  That means that this test
won't work:

  my $json  = q[ { "key": "value" } ];
  my $data  = decode_json($json);
  my $typed = JSON::Typist->new->apply_types( $data );

  cmp_deeply($typed, { key => "value" });

...because C<"value"> will refuse to match an object.  You I<could> wrap each
string or number to be compared in C<str()> or C<num()> respectively, but this
can be a hassle, as well as a lot of clutter.

C<jcmp_deeply> is exported by Test::Deep::JType, and behaves just like
C<cmp_deeply>, but plain numbers and strings are wrapped in C<str()> tests
rather than shallow ones, so they always compare with C<eq>.

To test that the input data matches the right type, other routines are exported
that check type as well as content.

=cut

=func jcmp_deeply

This behaves just like Test::Deep's C<jcmp_deeply> but wraps plain scalar and
number expectations in C<str>, meaning they're compared with C<eq> only,
instead of also asserting that the found value must not be an object.

=cut

sub jcmp_deeply {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  local $Test::Deep::LeafWrapper = \&Test::Deep::str;
  Test::Deep::cmp_deeply(@_);
}

=func jstr

=func jnum

=func jbool

=func jtrue

=func jfalse

These routines are plain old Test::Deep-style assertions that check not only
for data equivalence, but also that the data is the right type.

C<jstr>, C<jnum>, and C<jbool> take arguments, which are passed to the non-C<j>
version of the test used in building the C<j>-style version.  In other words,
you can write:

  jcmp_deeply(
    $got,
    {
      name => jstr("Ricardo"),
      age  => jnum(38.2, 0.01),
      calm => jbool(1),
      cool => jbool(),
      collected => jfalse(),
    },
  );

C<jtrue> and C<jfalse> are shorthand for C<jbool(1)> and C<jbool(0)>,
respectively.

=cut

sub jstr  { Test::Deep::all( Test::Deep::obj_isa('JSON::Typist::String'),
                             Test::Deep::str(@_)) }

sub jnum  { Test::Deep::all( Test::Deep::obj_isa('JSON::Typist::Number'),
                             Test::Deep::num(@_)) }

sub jbool {
  Test::Deep::all(
    Test::Deep::any(
      Test::Deep::obj_isa('JSON::XS::Boolean'),
      Test::Deep::obj_isa('JSON::PP::Boolean'),
    ),
    (@_ ? bool(@_) : ()),
  );
}

sub jtrue  { jbool(1) }
sub jfalse { jbool(0) }

1;
