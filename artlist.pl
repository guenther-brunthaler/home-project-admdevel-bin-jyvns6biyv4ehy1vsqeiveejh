# Create sorted list of articles, newest first
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/artlist.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Cwd;
use File::Find;
use File::Spec;


my $base= cwd;
my @f;
find(
 sub {
  return unless -f && /\.txt$/i;
  my($nd, $url, $f);
  $f= File::Spec->abs2rel(File::Spec->rel2abs($_), $base);
  open IN, '<', $_ or return;
  $nd= '';
  while (defined($_= <IN>)) {
   if (!defined($url)) {
    next if ($url)= m! ^ ( http://.*? ) \s* $ !x;
    $url= '';
   }
   next unless ($_)= /[,\s] (\d+ \s* [.-] \s* \d+ \s* [.-] \s* \d+) ,? \s* $/x;
   my($d, $m, $y);
   return unless
   ($y, $m, $d)= /(\d+) \s* - \s* (\d+) \s* - \s* (\d+)/x
   or ($d, $m, $y)= /(\d+) \s* \. \s* (\d+) \s* \. \s* (\d+)/x
   ;
   return if $y < 1995 || $y > 2100 || $d < 1 || $d > 31 || $m < 1 || $m > 12;
   $_= sprintf "%04d-%02d-%02d", $y, $m, $d;
   $nd= $_ if $_ gt $nd;
  }
  close IN or die;
  push @f, [$nd, $f, $url] if $nd gt '';
 }
 , '.'
);
open OUT, '>', '.articles-index.txt' or die $!;
foreach (sort {$b->[0] cmp $a->[0] or $a->[1] cmp $b->[1]} @f) {
 print OUT qq'$_->[0] "$_->[1]"';
 print OUT " ->\n$_->[2]" if $_->[2];
 print OUT "\n\n";
}
close OUT or die;
