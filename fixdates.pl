#! /usr/bin/perl
# Fixes all dates in the specified files.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/fixdates.pl 2647 2006-08-26T07:45:40.216781Z gb  $
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
