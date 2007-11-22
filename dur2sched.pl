# Input: A list of movie clip durations @ 25 fps, format [[HH:]MM:]SS:ff
# Output: List of absolute offsets from beginning in same format.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/dur2sched.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Getopt::Std;


sub HELP_MESSAGE {
 print <<".";
option -n: Assume input is [[HH]MM]NNSSFF instead of ':' separated items
.
}


our($VERSION)= q$Revision: 11 $ =~ /(\d+\.\d+)/;
my($h, $m, $s, $f, $a, %opt);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
die unless getopts('n', \%opt);
$opt{n}= $opt{n} ? '' : ':';
$a= 0;
while (<>) {
 die unless ($h, $m, $s, $f)= /
  ^
  (?:
   (?:
    (\d\d??) $opt{n}
   )??
   (\d\d??) $opt{n}
  )??
  (\d\d) $opt{n} (\d\d)
  $
 /xo;
 foreach ($h, $m) {$_= 0 unless defined $_}
 $f+= ($s + ($m + $h * 60) * 60) * 25;
 $a+= $f;
 $f= $a % 25;
 $s= int $a / 25;
 $m= int $s / 60;
 $s%= 60;
 $h= int $m / 60;
 $m%= 60;
 printf "%02d:%02d:%02d:%02d\n", $h, $m, $s, $f;
}
