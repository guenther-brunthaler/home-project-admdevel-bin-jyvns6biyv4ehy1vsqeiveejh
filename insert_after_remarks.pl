# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/insert_after_remarks.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
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
