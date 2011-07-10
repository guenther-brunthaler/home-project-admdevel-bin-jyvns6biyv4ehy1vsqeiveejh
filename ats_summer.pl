#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $Archive: /PRIVATE/GB/DATA/txt/Ansi/STRANDED.TXT $
# $Author: gb $
# $Modtime: 30.10.00 23:34 $ (DOLM)
# $Date: 2006-08-26T07:45:40.216781Z $ (Updated)
# $Revision: 2647 $
# $Nokeywords:$
# $xsa1$

while (<>) {
 if (/\s*(([-+])?\s*\b(?:(?:AT?)?S|(?:[Oo][Ee]|[Öö])[Ss])\s*([-\d+.,]+))/) {
  $ov= $1;
  $v= $3;
  $neg= $2 eq '-';
  $v=~ s/,-+$//;
  print("'$ov': invalid thousands separator") , next if $v=~ /^\.|\.$|\.\./;
  $v=~ s/\.//g;
  print("'$ov': too many decimal commas") , next if $v=~ /,.*,/;
  $v=~ tr/,/./;
  $v= -$v if $neg;
  $sum+= $v;
  print ++$i, qq@: "$ov" => @, sprintf("ATS %4.2lf", $v), "\n";
 }
}
print "Summe: ATS ", sprintf("%4.2lf", $sum), "\n";
