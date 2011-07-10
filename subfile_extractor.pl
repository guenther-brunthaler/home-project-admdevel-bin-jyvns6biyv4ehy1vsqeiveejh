#! /usr/bin/perl
# Extracts tagged subfiles from a binary data stream.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/subfile_extractor.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Long;
use Fcntl qw(:DEFAULT :seek);


my($opt_help, $opt_alignment, $opt_offset, $opt_bufsize);


$opt_offset= 0;
$opt_alignment= 1;
$opt_bufsize= 0x8000;
Getopt::Long::Configure("bundling");
my($revision)= '$Revision: 2647 $' =~ / ( \d+ (?: [\d.]* \d+ )? ) /x;
my $Usage= <<"END";
$0 extracts files contained within another file

This utility can be used to extract data files from an file system image
file if the files are stored contiguous and patterns are known which
identifies start and end of the individual files.

Usage: $0 [ options ] <file> <start_pat> <end_pat> <out_mask>

where:
<file>: The image file to be scanned.
<start_pat>: Pattern identifying the start of a file to extract.
             Can be specified in "C" syntax, i. e. may contain \n \x?? etc
<end_pat>: Pattern identifying the end of a file to extract. See <start_pat>.
<out_mask>: Filename mask for the output files. Must contain a substring
            made of one or more '#'-characters which will be replaced by a
            sequence number when the files are output.

options supported:
-h, --help: Display this help
--offset <bytes>: Start scanning at this offset.
                  Can be any valid Perl expression. Examples:
                  --offset "47 * 0x200"
                  --offset "47 << 9"
                  --offset 24_064
                  --offset 24064
--align <bytes>: Find <start_pat> only at offsets that are multiples of
                 this value. Can be any valid Perl expression.
--buffer-size <bytes>: The file will be processed in chunks of this size.
                       Should be small enough to fit completely into memory.
                       Defaults to $opt_bufsize.
                       Can be any valid Perl expression.

$0 Version $revision
written by Guenther Brunthaler in 2004
END
GetOptions(
 'h|help' => \$opt_help
 , 'offset=s' => \$opt_offset
 , 'align=s' => \$opt_alignment
 , 'buffer-size=s' => \$opt_bufsize
) or die $Usage;
if ($opt_help) {
 print $Usage;
 exit;
}
my $image_file= shift;
my $start_pat= shift;
my $end_pat= shift;
my $out_mask= shift;
die $Usage if @ARGV || !defined($out_mask);
foreach ($start_pat, $end_pat) {
 eval qq!\$_= "$_"!;
 die "Bad pattern" if $@;
}
foreach ($opt_alignment, $opt_offset, $opt_bufsize) {
 next unless defined;
 eval qq!\$_= $_!;
 die "Bad expression" if $@;
}
$out_mask =~ s/\%/\%\%/g;
$out_mask =~ s!(#+)! '%0' . length($1) . 'u' !e
or die "invalid output mask"
;
open IN, '<', $image_file or die "Cannot open '$image_file': $!";
binmode IN or die;
my($buf, $keep, $wanted, $fnum, $st, @st, $read, $i);
$keep= length($start_pat);
$keep= length($end_pat) if length($end_pat) > $keep;
$opt_bufsize= $keep + 1 if $opt_bufsize <= $keep;
if ($opt_offset > 0) {
 seek IN, $opt_offset, SEEK_SET or die "seek failure: $!";
}
for ($fnum= $st= 0;;) {
 if ($st == 0) {
  # Read first buffer.
  $i= 0;
  push @st, 2;
  $st= 1;
 }
 elsif ($st == 1) {
  # Read next buffer load at index $i.
  for ($wanted= $opt_bufsize; $wanted > 0; $i+= $read) {
   $read= read IN, $buf, $wanted, $i;
   die "error reading file: $!" unless defined $read;
   $wanted= 0 if $read == 0 && eof(IN);
   $wanted-= $read;
  }
  $i= 0;
  $st= pop @st;
 }
 elsif ($st == 2) {
  # Scan for starting pattern starting at index $i.
  die;
 }
}
close IN or die;
