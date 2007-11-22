use strict;
use FindBin;
use lib "$FindBin::Bin";
use File::Find;
use Lib::ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;


my(@f, $rpf, $out, $in);
find(
 sub {
  return unless /.html$/i;
  push @f, $File::Find::name;
 }
 , '.'
);
$rpf= new Lib::ReplacementFile;
foreach my $f (@f) {
 ($out, $in)= $rpf->create(-original_name => $f, -emulate => 0);
 print "Converting \"$f\"\n...";
 while (<$in>) {
  if (/(.*<\/html>)/i) {
   print $out "$1\n";
   last;
  }
  print $out $_;
 }
 $rpf->commit;
}
