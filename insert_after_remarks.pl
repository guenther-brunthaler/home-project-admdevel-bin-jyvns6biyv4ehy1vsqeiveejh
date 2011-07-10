#! /usr/bin/perl
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/insert_after_remarks.pl 2647 2006-08-26T07:45:40.216781Z gb  $
#
# Adds a revision tag after the first line beginning at "#".

$tag= shift @ARGV;
while (<>) {
 last unless /^#/;
 print;
 if (eof) {
  print $tag, "\n";
  exit;
 }
}
print $tag, "\n";
print;
while (<>) {
 print;
}
