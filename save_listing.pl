#!/usr/bin/perl
# Retrieve a listing of the files from some storage volume
# rooted at a specified mount point and save a text file
# containing the contents to a system-specific location.
# If the file to be saved already exists,
# it will be overwritten.
# $Date: 2007-11-12T10:01:21.140264Z $
# $Revision: 1030 $
# $Author: root $


# File format is a set of UTF-8 lines, "LC_ALL=C"-sorted by
# pathname.
# Each line has the format:
# DOLM BYTECOUNT PATHNAME
# where:
# DOLM: date of last modification, UTC, syntax:
#       YYYY-MM-DD HH:NN:SS
# BYTECOUNT: file size in bytes, at least 13 decimal digits,
# left-padded with spaces.
# PATHNAME: Path separator is '/', special characters must
# be escaped using \xNN reprentation. Special characters are
# '/', leading or trailing WS, WS other than ASCII SPC,
# and '\' which will be escaped as '\x5C'.
#
# Lines which are not confined to the syntax outlined above
# will be assumed to be comments and shall be ignored
# by processing tools.
#
# By convention, empty lines and lines starting with "#"
# shall be used for comments.


use strict;
use File::Spec;
use Getopt::Long;


# Preset directory where listings will be written to,
# Relative to $HOME unless specified as an absolute path.
# May be a symlink to the actual directory as well.
# Can be overriden by command line option.
our $listings_dir= '.offline_db';


sub qstr($) {
   return join '', map {
      sprintf '\\x%02X', $_
   } unpack 'C*', shift;
}


sub dolm($) {
   my @t= gmtime shift;
   return sprintf
      '%04u-%02u-%02u %02u:%02u:%02u'
      , $t[5] + 1900, $t[4] + 1, @t[3, 2, 1, 0]
   ;
}


sub emit_dir {
   my($fh, $prefix, $dir, $recursions)= @_;
   my(@e, $ad, $rf, $e, $size, $mtime);
   local *DIR;
   $ad= File::Spec->catdir($prefix, $dir);
   if (defined($recursions) && $recursions-- == 0) {
      $e= '.';
      $rf= $dir eq '' ? $e : File::Spec->catfile($dir, $e);
      $e= File::Spec->catfile($ad, $e);
      ($size, $mtime)= (stat _)[7, 9];
      print $fh dolm($mtime), sprintf('%13s', $size), ' ', $rf, "\n";
      return;
   }
   opendir DIR, $ad or die "Cannot read '$ad': $!";
   while (defined($e= readdir DIR)) {
      next unless File::Spec->no_upwards($e);
      push @e, $e;
   }
   closedir DIR or die;
   foreach $e (sort @e) {
      $rf= $dir eq '' ? $e : File::Spec->catfile($dir, $e);
      $e= File::Spec->catfile($ad, $e);
      next if -l $e;
      ($size, $mtime)= (stat _)[7, 9];
      if (-d _) {
         &emit_dir($fh, $prefix, $rf, $recursions);
      } else {
         $rf =~ s/^(\s+)/ qstr $1 /e;
         $rf =~ s/(\s+)$/ qstr $1 /e;
         $rf =~ s/([\s\\])/ $1 eq ' ' ? $1 : qstr $1 /eg;
         print $fh dolm($mtime), sprintf('%13s', $size), ' ', $rf, "\n";
      }
   }
}


my($label, $vol, $dir, $file, $cmt, $recursions, $ann_mode, $in_vg);
umask 0007;
Getopt::Long::Configure("bundling");
exit unless GetOptions(
   'h|?|help' => sub {
      print "Usage: $0 [ options] <mountpoint>";
      die "stopped";
   }
   , 'label|l=s' => \$label
   , 'max-depth|m=i' => \$recursions
   , 'listings-directory|d=s' => \$listings_dir
   , 'annotate-only|a' => \$ann_mode
);
my $root= shift || die;
die "'$root' does not exist" unless -d $root || -b $root;
unless ($label) {
   open MOUNT, '-|', "mount -l" or die $!;
   my($mp, $dev, $rootcmp);
   $rootcmp= qx(readlink -f "$root");
   chomp $rootcmp;
   die unless -d $rootcmp;
   foreach (<MOUNT>) {
      next unless /
         (.+?) [ ] on [ ] (.+?) [ ] type [ ] \S+
         (?: [ ] \( [^)]* \) )?
         [ ] \[ ( [^]]+ ) \]
      $/x;
      ($dev, $mp, $label)= ($1, $2, $3);
      # Check for matching mount point first.
      last if $mp eq $rootcmp;
      # Otherwise, check for matching device.
      next unless $dev eq $root;
      ($in_vg, $label, $root)= (1, $dev, $mp);
      $label =~ s!^/dev/!!;
      $label =~ s!/!-!g;
      last;
   }
   close MOUNT or die;
   die "$root is not an active mount point" unless $label;
   $label =~ s/[^-[:alnum:]]/_/g;
   $label =~ s/^_|_$//g;
}
unless ($in_vg) {
   $label =~ s/^([^-\d]+)/\U$1/i;
   $label =~ s/^([A-Z]+)_?(\d{8})$/$1-$2/;
}
open DFREE, '-|', "df --block-size=1 -P '$root' | tail -1" or die $!;
defined($cmt= <DFREE>) or die;
close DFREE or die;
{
   my @d= split /\s+/, $cmt;
   $cmt=
        sprintf("#%31s %s\n", $d[1], "(Total bytes)")
      . sprintf("#%31s %s\n", $d[2], "(Bytes in use)")
      . sprintf("#%31s %s\n", $d[3], "(Bytes free)")
   ;
   if ($recursions) {
      $cmt.= sprintf
         "#%31s %s\n", $recursions
         , "(Number of directory levels shown in listing below)"
      ;
   }
}
if (File::Spec->file_name_is_absolute($listings_dir)) {
   ($vol, $dir, $file)= File::Spec->splitpath($listings_dir, 1);
} else {
   $dir= $ENV{HOME} || die '$HOME is not set';
   ($vol, $dir, $file)= File::Spec->splitpath($dir, 1);
   $dir= File::Spec->catdir($dir, $listings_dir);
}
$dir= File::Spec->catpath($vol, $dir, '');
die "Listings directory '$dir' does not exist" unless -d $dir;
if ($ann_mode) {
   # Appends to .nfo files rather than creating .lst files.
   $file= File::Spec->catfile($dir, $label . ".nfo");
   print "Appending to annotation file '$file'...\n";
   open OUT, '>>', $file or die "Cannot create or append to '$file': $!";
   print OUT '-' x 15 . ' ' . gmtime() . ' ' . '-' x 15 . "\n";
   if (@ARGV) {
      print OUT map "$_\n", @ARGV;
   } else {
      print OUT while <>;
   }
} else {
   $file= File::Spec->catfile($dir, $label . ".lst");
   print "Creating listing file '$file'...\n";
   open OUT, '>', $file or die "Cannot create '$file': $!";
   print OUT $cmt;
   emit_dir *OUT{IO}, $root, '', $recursions;
}
close OUT or die "Cannot finish writing '$file': $!";
{
   # Attempt to set same owner as for directory. Might fail.
   my($uid, $gid)= (stat $dir)[4, 5];
   chown $uid, $gid, $file || chown -1, $gid, $file;
}
print "Done.\n";
