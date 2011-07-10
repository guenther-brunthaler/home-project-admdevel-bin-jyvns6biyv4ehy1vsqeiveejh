#! /usr/bin/perl
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/depxtr.pl 2647 2006-08-26T07:45:40.216781Z gb  $
#
# Extract a list of all files listed in a MSDEV-generated .dep file.


use strict;
use File::Spec::Functions qw(
 rel2abs splitdir catdir splitpath catpath curdir updir
);


sub normalize_path ($) {
 my(@f, @d, $i);
 @f= splitpath rel2abs shift;
 @d= splitdir $f[1];
 for ($i= 0; $i < @d; ) {
  if ($d[$i] eq updir) {
   die "invalid relative path" if $i <= 0;
   splice @d, --$i, 2;
   next;
  }
  elsif ($d[$i] eq curdir) {
   splice @d, $i, 1;
   next;
  }
  ++$i;
 }
 $f[1]= catdir @d;
 catpath @f;
}


my(%f, $f);
while (<>) {
 next if /^\s*#/;
 if (
  s/^\s* ("?) ([^"]+?) \1 \s* :? \s* \\ \s*$/$2/x
 ) {
  $f= normalize_path $2;
  $f{lc $f}= $f;
 }
}
foreach (sort keys %f) {
 print $f{$_}, "\n";
}
