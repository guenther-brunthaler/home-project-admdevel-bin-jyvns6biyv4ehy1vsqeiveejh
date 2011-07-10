#! /usr/bin/perl
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/extract_mozilla_boomark_ids.pl 2647 2006-08-26T07:45:40.216781Z gb  $
# Given a Mozilla Bookmarks.html file as input,
# outputs a list of all bookmarks IDs.
while(<>) {
 while (/ID="rdf:([^"]+)"/g) {
  print "$1\n";
 }
}
