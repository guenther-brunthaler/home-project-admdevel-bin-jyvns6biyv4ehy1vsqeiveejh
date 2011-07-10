#! /usr/bin/perl
# Removes a section of text from a PDF file.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/remove_pdf_section.pl 2647 2006-08-26T07:45:40.216781Z gb  $

# Lines that start the section (inclusive).
my $from= <<'.';
% ==================================================================== draft.ps
% Redefine showpage so "DRAFT" is printed in gray on all pages.  To
% change the intensity of the message, change the number in front of the
.
# Lines that end the section (inclusive).
my $to= <<'.';
% ========================================================= end of new showpage
.
my $outname= "David J.C. MacKay - Information Theory, Inference, and Learning Algorithms.ps";
my $inname= "$outname.in";


use strict;


my(@from, @to, @f, $i, $n, $m, $i1, $i2, $st);
foreach ([\$from, \@from], [\$to, \@to]) {
 my($var, $list)= @$_;
 @$list= map {"$_\x0a"} split /\n/, $$var;
}
open IN, '<', $inname or die $!;
open OUT, '>', $outname or die $!;
foreach (*IN{IO}, *OUT{IO}) {
 binmode $_ or die $!;
 select $_;
 $/= "\x0a";
}
$m= \@from;
$n= @$m;
$st= 0;
$i= 0; # Slot for first line.
OUTER: while (defined($_= <IN>)) {
 $f[$i]= $_;
 $i= 0 if ++$i >= $n;
 # Now on next slot to be filled.
 if (@f == $n) {
  # Also on oldest line in buffer.
  $i2= $i;
  for ($i1= 0; $i1 < $n; ++$i1) {
   if ($m->[$i1] ne $f[$i2]) {
    print OUT $f[$i] if $st == 0;
    next OUTER;
   }
   $i2= 0 if ++$i2 >= $n;
  }
  # Match.
  if ($st == 0) {
   $st= 1;
   $m= \@to;
  }
  else {
   $st= 0;
   $m= \@from;
  }
  $n= @$m;
  $i= 0;
  @f= ();
 }
}
# Flush buffer.
if (@f) {
 die unless $st == 0 || $st == 2;
 for ($i1= $i; ; ) {
  $i= 0 if ++$i >= @f;
  last if $i == $i1;
  print OUT $f[$i];
 }
}
close OUT or die $!;
close IN or die $!;
