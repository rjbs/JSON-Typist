use strict;
use warnings;
use Test::More;
use JSON::PP;
use JSON::Typist;

subtest "basic functionality" => sub {
  my $content = q<{"number":5,"string":"5"}>;

  my $json   = JSON::PP->new->convert_blessed->canonical;
  my $typist = JSON::Typist->new;

  my $payload  = $json->decode( $content );
  my $typed    = $typist->apply_types( $payload );

  isa_ok( $typed->{string}, 'JSON::Typist::String', '$typed->{string}');
  isa_ok( $typed->{number}, 'JSON::Typist::Number', '$typed->{number}');

  my $sink;
  $sink = 0 + $payload->{string};
  $sink = "$payload->{number}";

  $sink = 0 + $typed->{string};
  $sink = "$typed->{number}";

  my $via_payload   = $json->encode($payload);
  my $via_typed     = $json->encode($typed);

  my $stripped      = $typist->strip_types($typed);
  my $via_stripped  = $json->encode($stripped);

  isnt($via_payload, $content, "once inspected, original won't round trip");

  is($via_typed,    $content, "typed structure, inspected, does round trip");
  is($via_stripped, $content, "typed structure, stripped, also round trips");
};

subtest "bignums in effect" => sub {
  my $content = q<{"number":2.000000000000000000000000001}>;
  my $json    = JSON::PP->new->convert_blessed->allow_bignum;
  my $payload = $json->decode( $content );
  my $typist  = JSON::Typist->new;
  my $typed   = $typist->apply_types($payload);

  isa_ok($payload->{number}, 'Math::BigFloat',        '$payload->{number}');
  isa_ok($typed->{number},   'JSON::Typist::Number',  '$typed->{number}');

  my $sink = "$typed->{number}";

  my $via_typed     = $json->encode($typed);

  my $stripped      = $typist->strip_types($typed);
  my $via_stripped  = $json->encode($stripped);

  is($via_typed,    $content, "typed structured, inspected, does round trip");
  is($via_stripped, $content, "typed structured, stripped, also round trips");
};

done_testing;
