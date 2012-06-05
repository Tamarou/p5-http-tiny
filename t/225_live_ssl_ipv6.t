#!perl

use strict;
use warnings;

use Test::More 0.88;
use IO::Socket::IP;
BEGIN {
    eval 'use IO::Socket::SSL; 1';
    plan skip_all => 'IO::Socket::SSL required for SSL tests' if $@;
    # $IO::Socket::SSL::DEBUG = 3;

    eval 'use Mozilla::CA; 1';
    plan skip_all => 'Mozilla::CA required for SSL tests' if $@;
}
use HTTP::Tiny;

plan skip_all => 'Only run for $ENV{AUTOMATED_TESTING}'
  unless $ENV{AUTOMATED_TESTING};

plan skip_all => "Can't test SSL with http_proxy set"
  if $ENV{http_proxy};

plan 'skip_all' => "Set \$ENV{PERL_HTTP_TINY_IPV6_ADDRESS} to run these tests"
  unless $ENV{PERL_HTTP_TINY_IPV6_ADDRESS};

my $v6_local = $ENV{PERL_HTTP_TINY_IPV6_ADDRESS};
plan 'skip_all' => "Internet connection timed out"
  unless IO::Socket::IP->new(
    LocalAddr => $v6_local,
    PeerHost  => 'ipv6.google.com',
    PeerPort  => 443,
    Proto     => 'tcp',
    Timeout   => 10,
  );

my $data = {
    'https://ipv6.google.com/' => {
        host => 'ipv6.google.com',
        pass => { SSL_verifycn_scheme => 'http', SSL_verifycn_name => 'ipv6.google.com', SSL_verify_mode => 0x01, SSL_ca_file => Mozilla::CA::SSL_ca_file() },
        fail => { SSL_verify_callback => sub { 0 }, SSL_verify_mode => 0x01 },
        default_should_yield => '1',
    },
    'https://www.v6.facebook.com/' => {
        host => 'www.v6.facebook.com',
        pass => { SSL_verifycn_scheme => 'http', SSL_verifycn_name => 'www.v6.facebook.com', SSL_verify_mode => 0x01, SSL_ca_file => Mozilla::CA::SSL_ca_file() },
        fail => { SSL_verify_callback => sub { 0 }, SSL_verify_mode => 0x01 },
        default_should_yield => '1',
    },
};
plan tests => scalar keys %$data;


while (my ($url, $data) = each %$data) {
    subtest $url => sub {
        plan 'skip_all' => 'Internet connection timed out'
            unless IO::Socket::IP->new(
                LocalAddr => $v6_local,
                PeerHost  => $data->{host},
                PeerPort  => 443,
                Proto     => 'tcp',
                Timeout   => 10,
        );

        # the default verification
        my $response = HTTP::Tiny->new(verify_ssl => 1)->get($url);
        is $response->{success}, $data->{default_should_yield}, "Request to $url passed/failed using default as expected"
            or do {
                # $response->{content} = substr $response->{content}, 0, 50;
                $response->{content} =~ s{\n.*}{}s;
                diag explain [IO::Socket::SSL::errstr(), $response]
            };

        # force validation to succeed
        my $pass = HTTP::Tiny->new( SSL_options => $data->{pass} )->get($url);
        isnt $pass->{status}, '599', "Request to $url completed (forced pass)"
            or do {
                $pass->{content} =~ s{\n.*}{}s;
                diag explain $pass
            };
        ok $pass->{content}, 'Got some content';

        # force validation to fail
        my $fail = HTTP::Tiny->new( SSL_options => $data->{fail} )->get($url);
        is $fail->{status}, '599', "Request to $url failed (forced fail)"
            or do {
                $fail->{content} =~ s{\n.*}{}s;
                diag explain [IO::Socket::SSL::errstr(), $fail]
            };
        ok $fail->{content}, 'Got some content';
    };
}
