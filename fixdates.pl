# Fixes all dates in the specified files.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/fixdates.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
while (<>) {
 chomp;
 $m= (stat)[9];
 if ($m == -1) {
  if (1 == utime 0, 0, $_) {
   print "Fixed UNIX date for '$_'!\n";
  }
  else {
   print "Failed fixing UNIX date for '$_'!\n";
  }
 }
}
