#! /usr/bin/perl
# creates a checksum file for the current directory subtree.
use strict;
use File::Find;


sub update {
 my($source, $destination)= @_;
 my(@ss, @sd);
 die unless -f $source && -r _;
 @ss= stat _;
 # Check whether copying is necessary.
 if (-e $destination) {
  @sd= stat _;
  die unless -f _ && -r _;
  return if
   $ss[7] == $sd[7] # Same size.
   && $ss[9] == $sd[9] # Same modification time.
  ;
 }
 # Copy.
 print STDERR "Creating file '$destination'...\n";
 local(*IN, *OUT);
 my($buf, $rd);
 open IN, '<', $source or die;
 binmode IN;
 open OUT, '>', $destination or die;
 binmode OUT;
 for (;;) {
  die unless defined($rd= read IN, $buf, 0x2000);
  last unless length $buf;
  print OUT $buf;
 }
 close OUT or die;
 close IN or die;
 # Copy date stamp.
 die unless utime(@ss[8, 9], $destination) == 1;
}


my($f, @f, $of, $ud);
local(*STDOUT_SAVE);
$ud= 'Utilities';
unless (-e $ud) {
 print STDERR "Creating directory '$ud'...\n";
 mkdir $ud or die;
}
update 'U:/BIN/MD5SUM.EXE', $ud . '/md5sum.exe';
update 'M:/PERL/Specific/checkcd.bat', 'checkcd.bat';
$of= 'checksum.md5';
find(
 sub {
  return if $File::Find::name eq './' . $of || !-f;
  $f= $File::Find::name;
  die $f unless $f =~ s!^\./!!;
  push @f, $f;
 },
 '.'
);
print STDERR "Creating file '$of' containing checksums for ", scalar(@f);
print STDERR " files...\n";
@f= sort {lc($a) cmp lc($b)} @f;
open STDOUT_SAVE, ">&STDOUT" or die;
open STDOUT, '>', $of or die;
# BUG? - The next line does not work
#system(qq!echo -b \"ActiveState PERL\\ActivePerl-5.6.0.616-MSWin32-x86-multi-thread.msi\"!);
foreach (@f) {
 tr!/!\\!;
 $_= qq'md5sum -b "$_"';
 print STDERR "$_\n";
 system($_) == 0 or die;
}
close STDOUT or die;
open STDOUT, ">&STDOUT_SAVE" or die;
print STDERR "Done!\n";
