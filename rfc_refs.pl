# Converts 'References' Sections of RFC's into list of filenames for RFCs
# to be downloaded to local hard disk.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/rfc_refs.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


$_= join '', <>;
while (
 /
  \[ RFC (\d+) \] .+?
  " ([^"]+) "
 /sxg
) {
 ($rfc, $title)= ($1, $2);
 $title =~ s/\s+/ /sg; # Compress spaces/newlines into single space.
 $title =~ s/\.*$//g; # No trailing dots
 $title =~ s/\s*:\s+/ - /g; # Colons
 printf "rfc%04d - %s.txt\n", $rfc, $title;
}
