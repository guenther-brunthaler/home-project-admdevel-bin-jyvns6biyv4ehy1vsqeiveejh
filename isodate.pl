# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/isodate.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# Changes lines starting with day/month/y2(y4) into yyyy-mm-dd.
# Args: filename, 4-digit-year


use strict;
use lib 'M:\\var\\lib\\Dev\\Shared Scripts';
use Lib::ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;


my($rf, $in, $out, $m, $d, $y, $y4);
$rf= new Lib::ReplacementFile;
($out, $in)= $rf->create(-original_name => shift, -emulate => 0);
$y4= shift;
$y4= '????' unless defined($y4) && $y4 =~ /^\d\d\d\d$/ && $y4 > 1900;
while (defined($_= <$in>)) {
 if (
  ($d, $m, $y)= /
   ^ \s* (\d\d?) \s* \. # Leading space and day.
   \s* (\d\d?) \s* \. # Month.
   (
    (?: # No year.
     \s*
     \d (?: # 1-digit year.
      \d? # 2-digit year.
      (?: \d\d )? # 4-digit year.
     )?
    )?
   )
   (?! \d )
  /x
 ) {
  $y= substr $y4 . $y, -4;
  substr($_, $-[1], $+[3] - $-[1])= sprintf '%s-%02d-%02d', $y, $m, $d;
 }
 print $out $_;
}
$rf->commit;
