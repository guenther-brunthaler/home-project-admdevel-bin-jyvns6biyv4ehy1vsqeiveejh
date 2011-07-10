#! /usr/bin/perl
# Interprets an octet stream from a file as a base-256 number
# end outputs it in decimal.


use strict;
use bigint;


my($v, $b);
open IN, $ARGV[0] or die "Cannot read '$ARGV[0]': $!";
binmode IN or die;
die unless read IN, $b, 1e7;
close IN or die;
foreach (unpack 'C*', $b) {
   $v= $v * 256 + $_;
}
print "$v\n";
