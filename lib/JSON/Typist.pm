use strict;
use warnings;

package JSON::Typist;
# ABSTRACT: replace mushy strings and numbers with rigidly typed replacements

=head1 OVERVIEW

JSON is super useful and everybody loves it.  Woo!  Go JSON!  Good job!

In Perl, though, it's a bit of a pain sometimes.  In Perl, strings and numbers
mush all together and you're often not sure which you have.  Did the C<5> in
your C<$x> come from C<{"x":5}> or C<{"x":"5"}>?  By the time you're checking,
you very well may not know.

Often, that's just fine, because it doesn't matter inside your Perl program,
where numericality and stringicity are determined by operators, not values.
Other times, you need to know.  You might using JSON for interchange with a
system that needs its types in its values.  JSON::Typist is meant for this
problem.

L<JSON> (in its many variant forms) always returns numbers and strings in
distinguishable forms, but the distinction can be lost as the variables are
used.  (That's just a weird-o Perl problem.)  JSON::Typist is meant to take the
result of JSON-decoding I<immediately> before you use it for anything else.  It
replaces numbers and strings with objects.  These objects can be used like
numbers and strings, and JSON will convert them to the right type if
C<convert_blessed> is enabled.

=head1 SYNOPSIS

  my $content = q<{ "number": 5, "string": "5" }>;

  my $json = JSON->new->convert_blessed->canonical;

  my $payload = $json->decode( $content );
  my $typed   = JSON::Typist->new->apply_types( $payload );

  $typed->{string}->isa('JSON::Typist::String'); #true
  $typed->{number}->isa('JSON::Typist::Number'); # true

  say 0 + $payload->{string}; # prints 5
  say "$payload->{number}";   # prints 5

  say 0 + $typed->{string};   # prints 5
  say "$typed->{number}";     # prints 5

  say $json->encode($payload);
  say $json->encode($typed);

=cut

use B ();
use Params::Util qw(_HASH0 _ARRAY0);
use Scalar::Util qw(blessed);

{
  package JSON::Typist::Number;
  use overload '0+' => sub { ${ $_[0] } }, fallback => 1;
  sub new { my $x = $_[1]; bless \$x, $_[0] }
  sub TO_JSON { 0 + ${$_[0]} }
}

{
  package JSON::Typist::String;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
  sub new { my $x = $_[1]; bless \$x, $_[0] }
  sub TO_JSON { "${$_[0]}" }
}

=method new

  my $typist = JSON::Typist->new( \%arg );

This returns a new JSON::Typist.  There are no valid arguments to C<new> yet.

=cut

sub new {
  my ($class) = @_;

  bless {}, $class;
}

=method apply_types

  my $typed = $json_typist->apply_types( $data );

This returns a new variables that deeply copies the input C<$data>, replacing
numbers and strings with objects.  The logic used to test for number-or-string
is subject to change, but is meant to track the logic used by JSON.pm and
related JSON libraries.  The behavior on weird-o scalars like globs I<is
undefined>.

Note that property names, which becomes hash keys, do not become objects.  Hash
keys are always strings.

=cut

sub apply_types {
  my ($self, $data) = @_;

  return $data unless defined $data;
  unless (ref $data) {
    my $b_obj = B::svref_2object(\$data);  # for round trip problem
    my $flags = $b_obj->FLAGS;
    if ($flags & ( B::SVp_IOK | B::SVp_NOK ) and !( $flags & B::SVp_POK )) {
      return JSON::Typist::Number->new($data);
    } else {
      return JSON::Typist::String->new($data);
    }
  }

  return [ map {; $self->apply_types($_) } @$data ] if _ARRAY0($data);

  return { map {; $_ => $self->apply_types($data->{$_}) } keys %$data }
    if _HASH0($data);

  return JSON::Typist::Number->new($data)
    if blessed $data
    && ($data->isa('Math::BigInt') || $data->isa('Math::BigFloat'));

  return $data;
}

=method strip_types

  my $untyped = $json_typist->strip_types;

This method deeply copies its input, replacing number and string objects with
simple scalars that should become the proper JSON type.  Using this method
should not be needed if your JSON decoder has C<convert_blessed> enabled.

=cut

sub strip_types {
  my ($self, $data) = @_;

  return $data unless defined $data;

  if (blessed $data) {
    return $$data if $data->isa('JSON::Typist::Number')
                  or $data->isa('JSON::Typist::String');

    return $data;
  }

  return [ map {; $self->strip_types($_) } @$data ] if _ARRAY0($data);

  return { map {; $_ => $self->strip_types($data->{$_}) } keys %$data }
    if _HASH0($data);

  return $data;
}

1;
