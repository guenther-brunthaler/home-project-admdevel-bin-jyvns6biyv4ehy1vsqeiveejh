#! /usr/bin/perl
use strict;
my $emulate= 0;
# Array of replacements.
# Each replacement is an anonymouse list consisting of 2 elements:
# The search string and the replacement string.
# The search string can also be a regular expression quoted by 'qr'.
my @rplc= (
 [
  qr'\$xsa\d+:\d+\$.*windows\.h.*inclusion'
  => '$xsa{2E7485C0-BB51-11D5-991B-AF82242FF8D2}$ <windows.h> inclusion'
 ],
 [
  qr'\$xsa\d+\$.*windows\.h.*inclusion'
  => '$xsa{2E7485C0-BB51-11D5-991B-AF82242FF8D2}$ end of windows.h inclusion'
 ]
);


my($fn, $fnb);


foreach (@rplc) {
 unless (ref $_->[0]) {
  $_->[0]= quotemeta $_->[0];
  $_->[0]= qr/$_->[0]/;
 }
}
while ($fn= <>) {
 chomp $fn;
 next if $fn =~ /\.bak$/;
 next unless -w $fn;
 next unless open ORIG, '<', $fn;
 undef $fnb;
 OUTER: while (<ORIG>) {
  foreach my $r (@rplc) {
   if (/$r->[0]/) {
    $fnb= 1;
    last OUTER;
   }
  }
 }
 if ($fnb) {
  $fnb= $fn . '.bak';
  open BAK, '+>', $fnb or die;
  seek ORIG, 0, 0;
  print BAK while defined($_= <ORIG>);
  seek BAK, 0, 0;
 }
 close ORIG;
 if (defined $fnb) {
  print "replacing in file '$fn'\n";
  open ORIG, '>', $fn . ($emulate ? '.new.bak' : '') or die;
  while (<BAK>) {
   foreach my $r (@rplc) {
    if (/$r->[0]/) {
     $_= $` . $r->[1] . $';
    }
   }
   print ORIG;
  }
  close BAK or die;
  close ORIG or die;
 }
}
