#! /usr/bin/perl
# Permutation generator.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/generate-permutations.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Std;


sub HELP_MESSAGE {
 print <<".";
Usage: $0 options
where 'options' are one or more of the following:
-n <integer>: Specify the total number of elements (required)
-k <integer>:
 Specify the number of elements to use for arrangement.
 Defaults to the same value as specified for -n.
.
}


my($n, $k, $i1, $i2, $cmp, %opt);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
if (
   !getopts('n:k:', \%opt)
   || !defined $opt{n}
   || defined $opt{k} && $opt{n} < $opt{k}
) {
   die "Invalid paramters. Run '$0 --help' for help.";
}
$opt{k}||= $opt{n};
my($n, $k)= @opt{qw/n k/};
print "List of all possible permutations of $k elements out of $n:\n";
my $f= '%' . length($n) . 'u';
my @p= (1) x $k;
for (my $p= 0;; ) {
   for ($i1= @p; $i1--; ) {
      $cmp= $p[$i1];
      for ($i2= @p; $i2--; ) {
         goto increment if $i1 != $i2 && $cmp == $p[$i2];
      }
   }
   print "P($p) := (", join(", ", map sprintf($f, $_), @p) , ")\n";
   ++$p;
   increment:
   for ($i2= @p; $i2--; ) {
      last if ++$p[$i2] <= $n;
      $p[$i2]= 1;
   }
   last if $i2 < 0;
}
