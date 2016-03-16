use strict;
use warnings;

package JSON::Typist;

use B ();
use Params::Util qw(_HASH0 _ARRAY0);
use Scalar::Util qw(blessed);

{
  package JSON::Typist::Number;
  use overload '0+' => sub { ${ $_[0] } }, fallback => 1;
  sub new { my $x = $_[1]; bless \$x, $_[0] }
  sub TO_JSON { 0 + ${$_[1]} }
}

{
  package JSON::Typist::String;
  use overload '""' => sub { ${ $_[0] } }, fallback => 1;
  sub new { my $x = $_[1]; bless \$x, $_[0] }
  sub TO_JSON { "${$_[1]}" }
}

sub type_annotate {
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

  return [ map {; $self->type_annotate($_) } @$data ] if _ARRAY0($data);

  return { map {; $_ => $self->type_annotate($data->{$_}) } keys %$data }
    if _HASH0($data);

  return JSON::Typist::Number->new($data)
    if blessed $data
    && ($data->isa('Math::BigInt') || $data->isa('Math::BigFloat'));

  return $data;
}

1;
