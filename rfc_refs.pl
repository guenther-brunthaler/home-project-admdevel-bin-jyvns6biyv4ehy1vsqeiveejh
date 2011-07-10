#! /usr/bin/perl
# Converts 'References' Sections of RFC's into list of filenames for RFCs
# to be downloaded to local hard disk.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/rfc_refs.pl 2647 2006-08-26T07:45:40.216781Z gb  $


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
