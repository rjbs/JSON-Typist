use strict;
use warnings;
package JSON::Typist::DataPrinter;

# ABSTRACT: a helper for Data::Printer-ing JSON::Typist data

use Data::Printer use_prototypes => 0;
use Term::ANSIColor qw(colored);

our $STRING_COLOR = 'ansi46';
our $NUMBER_COLOR = 'bright_magenta';
our $BOOL_COLOR   = 'ansi214';

use Sub::Exporter -setup => [ qw( jdump ) ];

=head1 SYNOPSIS

  use JSON::Typist::DataPrinter qw( jdump );

  my $data = get_typed_data_from_your_code();

  say "I got data and here it is!";

  say jdump($data); # ...and you get beautifully printed data

=head1 OVERVIEW

This library exists for one reason: to provide C<jdump>.  It might change at
any time, but one thing is for sure:  it takes an argument to dump and it
returns a printable string describing it.

=func jdump

  my $string = jdump($struct);

This uses Data::Printer to produce a pretty printing of the structure, color
coding typed data and ensuring that it's presented clearly.  The format may
change over time, so don't rely on it!  It's meant for humans, not computers,
to read.

=cut

sub jdump {
  my ($value) = @_;

  return p(
    $value,
    (
      return_value  => 'dump',
      colored       => 1,
      show_readonly => 0,
      filters       => [
        {
          'Test::Deep::JType::jstr' => sub { colored([$STRING_COLOR], qq{"$_[0]"}) },
          'Test::Deep::JType::jnum' => sub { colored([$NUMBER_COLOR], 0 + $_[0]) },
          'JSON::PP::Boolean'       => sub { colored([$BOOL_COLOR], $_[0] ? 'true' : 'false') },
        }
      ],
    )
  );
}

1;
