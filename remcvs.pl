#! /usr/bin/perl
# Removes any CVS-specific entries from a file containing only pathnames
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/remcvs.pl 2647 2006-08-26T07:45:40.216781Z gb  $
while (<>) {
 print unless m!(?:^|[/\\:])CVS(?:$|[/\\:])!i
}
