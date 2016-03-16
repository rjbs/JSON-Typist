use strict;
use warnings;
use Data::Dumper;
use JSON::PP;
use JSON::Typist;

$Data::Dumper::Sortkeys = 1;

my $JSON = JSON::PP->new;

my $json = q<{"num":123, "str":"this is a string"}>;

warn Dumper({
  input  => $json,
  output => $JSON->decode($json),
  typed  => JSON::Typist->type_annotate($JSON->decode($json)),
});
