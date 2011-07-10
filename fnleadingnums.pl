#! /usr/bin/perl
# Examine the filenames in the specified directory
# and extract their leading numeric prefixes.
# Then print a list of prefixes and/or prefix ranges.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/fnleadingnums.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use FindBin;
use lib "$FindBin::Bin";
use File::Spec;
use ExpandFilelist_57D9097A_926F_11D6_951B_009027319575;


my @f= @ARGV;
ExpandFilelist(\@f, -expand_globs => 1);
my $len;
foreach (@f) {
   $_= (File::Spec->splitpath($_))[-1];
   s/^(\d*).*/$1/;
   $len= length if !defined($len) || length && length() < $len; 
}
die unless $len;
@f= sort grep length == $len, @f;
for (my $i= 1; $i < @f; ) {
   if ($f[$i] eq $f[$i - 1]) {
      splice @f, $i - 1, 1;
      next;
   }
   ++$i;
}
my $j;
for (my $i= 0; $i < @f; ) {
   my $n= $f[$i];
   for ($j= $i; $j < @f; ++$j) {
      last if $f[$j] ne $n++;
   }
   if (--$j > $i + 1) {
      splice @f, $i, $j + 1 - $i
         , sprintf "%0*u-%0*u", $len, $f[$i], $len, $f[$j]
      ;
   }
   ++$i;
}
print join(" ", @f), "\n";
