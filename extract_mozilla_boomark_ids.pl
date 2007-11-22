# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/extract_mozilla_boomark_ids.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# Given a Mozilla Bookmarks.html file as input,
# outputs a list of all bookmarks IDs.
while(<>) {
 while (/ID="rdf:([^"]+)"/g) {
  print "$1\n";
 }
}
