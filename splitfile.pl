# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


my $op= 1;
while (<>) {
 if (s/^#\s*(.*?)\s*$/$1/) {
  close OUT if $op;
  open OUT, '>', $_ or die "Cannot create output file '$_': $^E";
  $op= 1;
 }
 elsif ($op) {
  print OUT;
 }
 else {
  die "First line must contain '#'-statement" unless $op;
 }
}
close OUT if $op;
