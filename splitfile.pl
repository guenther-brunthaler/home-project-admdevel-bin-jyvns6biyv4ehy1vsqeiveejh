#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
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
