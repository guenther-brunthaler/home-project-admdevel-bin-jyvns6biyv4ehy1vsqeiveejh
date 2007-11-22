# Rename Margarethe's OLYMPUS Pictures


use strict;
use Fcntl qw(SEEK_SET);


while (<P???????.JPG>) {
 next unless /^P\d{7}.JPG$/i;
 my($o, $n, $d);
 open IN, '<', ($o= $_) or die $!;
 binmode IN or die $!;
 seek IN, 0xa18, SEEK_SET or die $!;
 read(IN, $d, 19) == 19 or die $!;
 $d =~ s/^(\d\d\d\d):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)$/$1-$2-$3 $4$5$6/ or die;
 close IN or die $!;
 $n= "$d.jpg";
 print "Renaming '$o' => '$n'\n";
 rename $o, $n or die $!;
}
