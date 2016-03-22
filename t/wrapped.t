use strict;
use warnings;
use Test::More;
use JSON::PP;
use JSON::Typist;

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

is($via_typed, $content, "typed structure, inspected, does round trip");
is($via_stripped, $content, "typed structure, stripped, also round trips");

done_testing;
