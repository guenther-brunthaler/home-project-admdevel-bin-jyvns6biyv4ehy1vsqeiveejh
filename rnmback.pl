#! /usr/bin/perl
use File::Find;
find (
 sub {
  return unless /^(.+)\.bak$/ && -f && -w _;
  $nn= $1;
  return if /\.orig\d*\.bak$/;
  print "from '$_' into '$nn'\n";
  if (-e $nn) {
   $xn= '';
   ++$xn while -e ($xxn= "$nn.orig$xn.bak");
   rename $nn, $xxn or die;
  }
  rename $_, $nn or die;
 },
 @ARGV ? @ARGV : '.'
);
