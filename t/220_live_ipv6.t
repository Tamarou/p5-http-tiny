#!perl

use strict;
use warnings;

use IO::Socket::IP;
use Test::More 0.88;
use HTTP::Tiny;

my $test_host = "ipv6.google.com";
my $test_url  = "http://ipv6.google.com/";
my $test_re   = qr/google/;

plan 'skip_all' => "Only run for \$ENV{AUTOMATED_TESTING}"
  unless $ENV{AUTOMATED_TESTING};

plan 'skip_all' => "Set \$ENV{PERL_HTTP_TINY_IPV6_ADDRESS} to run these tests"
  unless $ENV{PERL_HTTP_TINY_IPV6_ADDRESS};

my $v6_local = $ENV{PERL_HTTP_TINY_IPV6_ADDRESS};
plan 'skip_all' => "Internet connection timed out"
  unless IO::Socket::IP->new(
    LocalAddr => $v6_local,
    PeerHost  => $test_host,
    PeerPort  => 80,
    Proto     => 'tcp',
    Timeout   => 10,
  );

my $response = HTTP::Tiny->new->get($test_url);

ok( $response->{status} ne '599', "Request to $test_url completed" )
  or dump_hash($response);
ok( $response->{content}, "Got content" );

sub dump_hash {
  my $hash = shift;
  $hash->{content} = substr($hash->{content},0,160) . "...";
  require Data::Dumper;
  my $dumped = Data::Dumper::Dumper($hash);
  $dumped =~ s{^}{# };
  print $dumped;
}

done_testing;
