#! /usr/bin/perl
use strict;
use MP3::Tag;

opendir DIR, '.' or die $!;
OUTER: while (defined(my $file= readdir DIR)) {
   next unless -f $file && $file =~ /\.(?i:mp3)$/;
   my $mp3= MP3::Tag->new($file);
   my($title, $track, $artist, $album, $comment, $year, $genre)
      = $mp3->autoinfo()
   ;
   undef $mp3;
   next unless $artist && $title;
   my $ins= '';
   if ($album gt '' && $track =~ /^(\d+)/) {
      $ins= sprintf " - %s - %02u", $album, $1;
   }
   my $nn= "$artist$ins - $title.mp3";
   my $tn= sprintf "mp3~%04u.tmp", int rand 10000;
   for (;;) {
      print "Rename '$file' into '$nn'?";
      my $q;
      {
         local $|= 1;
         print " ";
         $q= <STDIN>;
      }
      last OUTER if $q =~ /^q/i;
      next OUTER if $q =~ /^n/i;
      last if $q =~ /^[jy]/i;
   }
   print "Renaming '$file' into '$nn'... ";
   rename $file, $tn or die "Cannot rename '$file' into '$tn'";
   rename $tn, $nn or die "Cannot rename '$tn' into '$nn'";
   print "Done.\n\n";
}
closedir DIR or die;
