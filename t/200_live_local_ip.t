#!perl

use strict;
use warnings;

use IO::Socket::INET;
use Test::More 0.88;
use HTTP::Tiny;

my $test_host = "checkip.dyndns.org";
my $test_url  = "http://checkip.dyndns.org/";

plan 'skip_all' => "Only run for \$ENV{AUTOMATED_TESTING}"
  unless $ENV{AUTOMATED_TESTING};

plan 'skip_all' => "Set \$ENV{PERL_HTTP_TINY_LOCAL_IP} to run these tests"
  unless $ENV{PERL_HTTP_TINY_LOCAL_IP};

my $local_address = $ENV{PERL_HTTP_TINY_LOCAL_IP};

plan 'skip_all' => "Internet connection timed out"
  unless IO::Socket::INET->new(
    PeerHost  => $test_host,
    PeerPort  => 80,
    LocalAddr => $local_address,
    Proto     => 'tcp',
    Timeout   => 10,
  );

my $tiny = HTTP::Tiny->new(local_address => $local_address);
my $response = $tiny->get($test_url);

ok( $response->{status} ne '599', "Request to $test_url completed" )
  or dump_hash($response);
ok( $response->{content}, "Got content" );
ok( index($response->{content}, $ENV{PERL_HTTP_TINY_LOCAL_IP}),
  "We made the request from user-specified local IP" );

sub dump_hash {
  my $hash = shift;
  $hash->{content} = substr($hash->{content},0,160) . "...";
  require Data::Dumper;
  my $dumped = Data::Dumper::Dumper($hash);
  $dumped =~ s{^}{# };
  print $dumped;
}

done_testing;
