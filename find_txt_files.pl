#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;
use File::Find;


# Note that this technique does not allow files containing trash
# bytes after CTRL-Z under Windows.
sub istext {
 my($fn)= @_;
 local(*IN);
 return undef unless open IN, '<', $fn;
 binmode IN;
 my(@buf, $bi, $bi2, $rd, $anything, $z);
 $bi= 0; $bi2= 1;
 while (($rd= read IN, $buf[$bi], 0x1000) != 0) {
  goto faileed unless defined $rd;
  $anything= 1;
  if ($^O eq 'MSWin32') {
   goto failed if $buf[$bi] =~ /[^\x20-\x7e\xa0-\xff\x0a\x0d\x09\x0c\x1a]/;
   if (substr($buf[$bi], 0, 1) eq "\x0a") {
    goto failed unless substr($buf[$bi2], -1) eq "\x0d";
   }
   goto failed if $buf[$bi] =~ /\x0d[^\x0a]|[^\x0d]\x0a]/;
   if (($z= index $buf[$bi], "\x1a") >= 0) {
    goto failed if $z != length($buf[$bi]) - 1;
    goto failed if read(IN, $buf[$bi2], 1) != 0;
    last;
   }
   ($bi, $bi2)= ($bi2, $bi);
  }
  else {
   goto failed if $buf[$bi] =~ /[^\x20-\x7e\xa0-\xff\x0a\x09\x0c]/;
  }
 }
 close IN;
 return $anything;
 failed:
 close IN;
 return undef;
}


find(
 sub {
  my $f= $_;
  local $_;
  print "$File::Find::name\n" if -f $f && -r _ && istext($f);
 },
 @ARGV ? @ARGV : '.'
);
