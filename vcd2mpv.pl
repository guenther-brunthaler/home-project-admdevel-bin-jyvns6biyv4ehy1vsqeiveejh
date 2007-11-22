# Extracts ".mpv" MPEG-2 file for use in DVD2AVI from
# the extracted contents of a Video CD RIFF "data" chunk.
#
# MPEG-1 start: 0x000001ba 0x2???????
# MPEG-1 end: 0x000001b9
# MPEG-2 start: 0x000001ba 0x4???????
# MPEG-2 end: 0x000001b9
#
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/vcd2mpv.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Fcntl qw(:DEFAULT :seek);
use Getopt::Std;


my $fn;
our $opt_o= 0x18; # Start offset.
our $opt_t= 4; # Truncate length by this.
our $opt_b= 0x8000; # Buffer size.
$Getopt::Std::STANDARD_HELP_VERSION= 1;
getopt('o:t:b:');
foreach ($opt_o, $opt_t, $opt_b) {
   if (defined) {
      my $r= eval $_;
      die "Bad value expression '$_': $@" if $@;
      $_= $r;
   }
}
open IN, '<', $fn= $ARGV[0] or die $!;
binmode IN or die;
seek IN, $opt_o, SEEK_SET or die $!;
$fn =~ s/(?:\.[^.]*)?$/.mpv/ or die;
open OUT, '>', $fn or die $!;
binmode OUT or die;
my($read, $buf);
for (;;) {
   die unless defined($read= read IN, $buf, $opt_b);
   last if $read == 0 && eof IN;
   print OUT $buf;
}
close OUT or die $!;
close IN or die;
truncate $fn, (-s $fn) - $opt_t or die $!;
