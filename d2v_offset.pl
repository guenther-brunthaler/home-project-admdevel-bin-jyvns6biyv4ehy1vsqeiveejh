# Report the starting frame offset between a specified .d2v-file starting
# at some frame and a prefix file of the same .d2v-source which starts at the
# beginning and ends at an offset larger than the start of the first file.
#
# That is, it tells at which absolute frame the file starts, which is essential
# to know for subtitle time correction if the extracted part of a ripped movie
# does not start at the very beginning of the DVD video stream.
#
# Also convert any times specified on the command line.
#
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/d2v_offset.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Getopt::Std;
use StringUtil_ED0113F0_9F17_11D9_BFF3_00A0C9EF1631 qw(is_prefix);


sub frame_time($$$;$) {
   my($u, $freq, $ups, $digs)= @_;
   my($h, $m, $s);
   $u= int $u * $ups / $freq;
   $s= int $u / $ups;
   $m= int $s / 60;
   $h= int $m / 60;
   $digs= $digs || 1;
   return
      sprintf "\%02u:\%02u:\%02u.\%0${digs}u", $h, $m % 60, $s % 60, $u % $ups
   ;
}


sub open_before_offset1($) {
   my $fn= shift;
   open IN, '<', $fn or die "cannot open '$fn': $!";
   while (<IN>) {
      if (/^Location=/) {
         last unless defined($_= <IN>);
         last unless /^$/;
         return;
      }
   }
   close IN;
   die "Invalid .d2v file: '$fn'"
}


my($h, $m, $s, $d, %opt, $prefix_file, $main_file);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 11 $' =~ /(\d[\d.]*)/;
$opt{f}= 25;
unless (
   getopts('pvf:o:', \%opt)
   and $prefix_file= shift and $main_file= shift
) {goto Usage}
eval {
   foreach (@ARGV) {
      unless (
         ($h, $m, $s, $d)= /
            ^
            (?:
               (?: (\d{1,2}) [:]? )? # "HH:"
               (\d{1,2}) [:]? # "MM:"
            )??
            (\d{1,2}) # "SS"
            (?: [,.] (\d{1,3}) )? # ".ddd"
            $
         /x
      ) {
         Usage:
         die
              "Usage: $0 [ <options> ] <prefix_file>.d2v <main_file>.d2v\n"
            . "          [ <hh:mm:ss.ddd> ... ]\n"
            . "options:\n"
            . "-v: be verbose\n"
            . "-f <fps>: SMPTE timing base is <fps> frames per second"
            . " (default 25)\n"
            . "-p: pause - wait for any key at the end\n"
            . "-o <file>: also create frame offset info file <file>\n"
      }
      $_= ((($h || 0) * 60 + ($m || 0)) * 60 + $s) * 1000 + ($d || 0);
   }
   foreach ($prefix_file, $main_file) {
      die "cannot locate '$_': $!" if defined && (!-f || !-r _);
   }
   if ($opt{v}) {
      print
              "prefix file starting with the missing initial frames:"
            . " '$prefix_file'\n"
         , "main file without initial frames: '$main_file'\n"
      ;
   }
   open_before_offset1 $main_file;
   my $end= <IN>;
   die unless defined $end;
   chomp $end;
   $end =~ s/^(7 \d+ [[:xdigit:]]+ )[0-39](?: [0-39])*$/$1/ or die;
   close IN or die;
   open_before_offset1 $prefix_file;
   my $off= 0;
   my @frames;
   while (<IN>) {
      if (is_prefix $end, $_) {
         undef $end;
         last;
      }
      chomp;
      print "$_ " if $opt{v};
      s/^7 \d+ [[:xdigit:]]+ ([0-39](?: [0-39])*)$/$1/ or
         die "invalid '$prefix_file' line format: '$_'"
      ;
      @frames= split / /;
      $off+= @frames;
      print " = ", scalar(@frames), " frames -> next offset $off\n" if $opt{v};
   }
   close IN or die;
   die "'$prefix_file' is not a prefix of '$main_file'" if defined $end;
   if (@ARGV == 0 || $opt{v}) {
      print
           "Initial frame of '$main_file'\n"
         , "is the same as frame $off of '$prefix_file'\n"
         , "which refers to absolute SMPTE "
         , frame_time($off, $opt{f}, $opt{f}, 2), " (at $opt{f} fps)\n"
         , "and absolute time ", frame_time($off, $opt{f}, 1000, 3), "\n"
      ;
   }
   else {
      print "Time shift offset is $off frames at $opt{f} fps\n";
   }
   if ($opt{o}) {
      open OUT, '>', $opt{o} or
         die "Could not create frame offset info file '$opt{o}': $!"
      ;
      print OUT
           "$off\n"
         , "SMPTE "
         , frame_time($off, $opt{f}, $opt{f}, 2), " (at $opt{f} fps)\n"
         , "DECIMAL ", frame_time($off, $opt{f}, 1000, 3), "\n"
      ;
      close OUT or die "Cannot finish writing '$opt{o}': $!";
   }
   foreach (@ARGV) {
      my $ms= $_ + $off * int 1000 / $opt{f};
      print
         "Relative ", frame_time($_, 1000, 1000, 3), " -> SMPTE "
         , frame_time($ms, 1000, $opt{f}, 2), " @ $opt{f} fps = "
         , frame_time($ms, 1000, 1000, 3), " absolute.\n"
      ;
   }
};
print STDERR $@ if $@;
if ($opt{p}) {
   local $|;
   $|= 1;
   print "\nPlease press [Enter] now to complete execution! ";
   <STDIN>;
}
