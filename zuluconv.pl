#! /usr/bin/perl
# Converts file names between local time and UTC format
# and optionally adds a specified hour/minute/second time offset.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/zuluconv.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Std;
use Time::Local qw(timelocal_nocheck timegm_nocheck);


sub HELP_MESSAGE {
 print <<".";
Usage: $0 [ options ... ]

$0 converts file names from the current directory
between local time and UTC format and optionally adds a specified
hour/minute/second time offset.

Files matching format YYYYMMDD-hhmmnn*.* are converted from local time to UTC.
Files matching format YYYYMMDDThhmmnn*.* are converted from UTC to local time.
Files names not matching either pattern are not converted at all.

Only the names of the matching file will be changed; the file contents will
not be touched at all.

Options:
-a "+hh:mm:ss": Add the specified time offset to all converted times.
-a "-hh:mm:ss": Subtract the specified time offset from all converted times.
-m: Also set the modification time of the file to the converted time.
-d: Dry-run. Display what would be done, but actually don't do it.
-v: Use verbose diagnostics.
--help: Show this help.
.
}


my(%opt, $fm, $fs, $ff, $nn);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
if (!getopts('dvma:', \%opt)) {
   die "Invalid paramters. Run '$0 --help' for help.";
}
if ($opt{a}||= 0) {
   my($n, $h, $m, $s);
   unless (
      $opt{a} =~ /^(?:(-)|\+)(\d\d):(\d\d):(\d\d)$/
      && ($n= $1, $h= $2) < 24 && ($m= $3) < 60 && ($s= $4) < 60
   ) {
      die "bad time offset";
   }
   $opt{a}= ($h * 60 + $m) * 60 + $s;
   $opt{a}= -$opt{a} if $n;
}
$fm= $fs= $ff= 0;
opendir DIR, '.' or die "Cannot read current directory: $!";
my @F= readdir DIR;
closedir DIR or die $!;
{
   my($utc, $tail, $tm, @v1, @v2, $i);
   foreach (@F) {
      unless (
         /
            ^ (\d\d\d\d) -? (\d\d) -? (\d\d)
            (?: - | ([TtZz]) )
            (\d\d) (\d\d) (\d\d)
            (?! \d) \s*
            (.*)
         /x
         && ($v1[5]= $1) > 1900
         && ($v1[5]-= 1900, $v1[4]= $2) >= 1
         && (--$v1[4], $v1[3]= $3) >= 1
         && -f
      ) {next}
      ++$fm;
      $utc= $4; @v1[2, 1, 0]= ($5, $6, $7); $tail= $8;
      substr($tail, 0, 0)= " " if $tail !~ / ^ \. | ^ $ /x;
      $tm= &{$utc ? \&timegm_nocheck : \&timelocal_nocheck}(@v1);
      @v2= &{$utc ? sub {gmtime shift} : sub {localtime shift}}($tm);
      @v2= @v2[0 .. 5];
      if (@v1 != @v2) {
         ignore_file:
         if ($opt{v}) {
            print "Ignoring file name with illegal date/time: '$_'.\n";
         }
         ++$fs;
         next;
      }
      for ($i= @v1; $i--; ) {
         goto ignore_file if $v1[$i] != $v2[$i];
      }
      $tm+= $opt{a};
      @v2= &{$utc ? sub {localtime shift} : sub {gmtime shift}}($tm);
      @v2= (@v2[0 .. 3], $v2[4] + 1, $v2[5] + 1900);
      $nn= sprintf(
         '%04u%02u%02u%s%02u%02u%02u%s'
         , @v2[5, 4, 3], ($utc ? '-' : 'T'), @v2[2, 1, 0], $tail
      );
      if ($opt{d}) {
         print "Renaming '$_' into '$nn'.\n" 
      } else {
         unless (rename $_, $nn) {
            print "Cannot rename '$_' into '$nn': $!\n";
            ++$ff;
            next;
         }
         if ($opt{m}) {
            if (1 != utime $tm, $tm, $nn) {
               print "Cannot set modification date/time for '$nn': $!\n";
            }
         }
      }
   }
}
if ($opt{v}) {
   print "$fm total matching file(s), $fs of which were skipped.\n";
   print "$ff file(s) could not be renamed.\n";
   print "(Results are simulated.)\n" if $opt{d};
}
