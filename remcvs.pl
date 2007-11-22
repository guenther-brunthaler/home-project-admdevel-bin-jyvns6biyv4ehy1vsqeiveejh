# Removes any CVS-specific entries from a file containing only pathnames
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/remcvs.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
while (<>) {
 print unless m!(?:^|[/\\:])CVS(?:$|[/\\:])!i
}
