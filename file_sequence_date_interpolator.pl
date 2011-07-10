#! /usr/bin/perl
# Interpolates the modification datestamps of a sequence of files
# assuming that the sorted file name sequence actually refers to files
# that should have datestamps in that order.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/file_sequence_date_interpolator.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;


my $Usage= <<".";
Usage: $0 <directory>

$0 assumes that
<directory> contains a series of filenames which, when sorted,
should also reflect the order of the file/time stamps.

When it finds files with time stamps contradicting the file name order,
it replaces them by interpolated stamps.
.


# Returns a linear interpolation of a f($x)
# where $x is in the range $xmin to $xmax,
# f($xmin) == $valxmin and f($xmax) == $valxmax
sub interpolate($$$$$) {
   my($x, $xmin, $xmax, $valxmin, $valxmax)= @_;
   die unless $xmin <= $xmax;
   die unless $x >= $xmin && $x <= $xmax;
   ($x - $xmin) * ($valxmax - $valxmin)
   / ($xmax == $xmin ? 1 : $xmax - $xmin)
   + $valxmin
   ;
}


my $dir= shift;
die $Usage if !$dir || !-d $dir || !-r $dir;
my(@f);
opendir DIR, $dir or die $!;
$dir.= "/" unless $dir =~ /[\/\\]$/;
{
   my @s;
   while (defined($_= readdir DIR)) {
      next unless -f "$dir$_";
      die unless -r _ and @s= stat(_);
      push @f, {name => $_, time => $s[9]};
   }
}
closedir DIR or die;
@f= sort {$a->{name} cmp $a->{name}} @f;
{
   my $g= $f[0]->{g}= 0;
   for (my $i= 1; $i < @f; ++$i) {
      $f[$i]->{g}= $f[$i]->{time} >= $f[$i - 1]->{time} ? $g : ++$g;
   }
   for (my $i= @f; $i-- > 0; ) {
      if ($f[$i]->{g} != ($g= $f[$i - 1]->{g})) {
         # At first entry of new group.
         # Find first entry of previous group.
         my($j, $oi);
         for ($j= $i - 1; $j > 0; --$j) {
            last if $f[$j - 1]->{g} != $g;
         }
         # Merge groups with contained interruption if possible.
         $g= $f[$i]->{g};
         $oi= $i;
         $i= $j + 1;
         while ($j < $oi && $f[$j]->{time} <= $f[$oi]->{time}) {
            $f[$j++]->{g}= $g;
         }
      }
   }
   # Identify enclosed groups and interpolate contents.
   for (my $i= 1; $i + 1 < @f; ++$i) {
      if ($f[$i - 1]->{g} != $f[$i]->{g}) {
         # First entry of new group.
         my $j;
         $g= $f[$i - 1]->{g};
         for ($j= $i + 1; $j < @f; ++$j) {
            last if $f[$j]->{g} == $g;
         }
         if ($j < @f) {
            my $k= $i - 1;
            my($v0, $vN)= ($f[$k]->{time}, $f[$j]->{time});
            while ($i < $j) {
               $f[$i]->{new}= int interpolate($i, $k, $j, $v0, $vN) + .5;
               ++$i;
            }
         }
      }
   }
}
@f= grep defined $_->{new}, @f;
foreach (@f) {
   my $f= "$dir$_->{name}";
   print "Re-stamping '$f'...\n";
   if (utime($_->{new}, $_->{new}, $f) != 1) {
      warn "Warning: Could not stamp '$f'!\n";
   }
}
if (@f == 0) {
   print "There's nothing to do, all files are in order already!\n";
}
