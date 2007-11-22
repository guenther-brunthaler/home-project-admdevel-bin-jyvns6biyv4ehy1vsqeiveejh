# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/randtext.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
#
# Generates lots of paragraphs of random text.


use strict;
use Getopt::Std;


our($opt_s, $opt_b, $opt_p, $opt_f, $opt_n, $opt_w);
my($bytes, $fh);


sub wrstr {
 my $str= shift;
 print $fh $str;
 $bytes-= length $str;
}


sub genword {
 my $c= shift;
 my $w= '';
 while ($c--) {
  $w.= chr int(rand(ord('z') - ord ('a'))) + ord('a');
 }
 $w;
}


sub wrword {
 my($c, $u)= @_;
 $u||= rand() < .3;
 my $w= genword $c;
 substr($w, 0, 1)= uc substr $w, 0, 1 if $u;
 wrstr $w;
}


sub wrsent {
 my $w= shift;
 my $f= 1;
 while ($w--) {
  wrstr " " unless $f;
  wrword int 2 + rand 10, $f;
  $f= 0;
 }
 wrstr ".";
}


sub wrpara {
 my $s= shift;
 my $f= 1;
 while ($s--) {
  if ($f) {
   $f= 0;
  } else {
   wrstr " ";
  }
  wrsent int 3 + rand 20;
 }
 wrstr "\n\n";
}


sub wrtext {
 $bytes= int rand 5e6 unless defined($bytes= $opt_b);
 while ($bytes > 0) {
  wrpara int 1 + rand 10;
 }
}


die <<"END" unless getopts('ns:b:f:p:w:') && @ARGV == 0;
Usage: $0 [ options ... ]

Options:
-b <bytes_to_create>: the approximate size of the output
-s <seed>: seed random number generator for repeatable sequences
-f <num>: generate that number of random files files containing the text
-p <pattern>: no random file names, specifies pattern, '%num%' is replaced
              by random string <num> characters wide. Defaults to '%8%.txt'.
              Shorthand: '%%' in the pattern is interpreted as '%1%'.
-n: modifies -p to use increasing integers of at least <num> digits instead
    of random string.
-w <num>: special mode - generate just <num> words
END
srand $opt_s if defined $opt_s;
if (defined $opt_w) {
 $fh= *STDOUT{IO};
 for ($bytes= 0; $opt_w; --$opt_w) {
  print $fh ' ' if $bytes < 0;
  wrword int 15 + rand 5;
 }
 exit;
}
$opt_f= 1 if !defined($opt_f) && (defined($opt_p) || defined($opt_n));
if ($opt_f) {
 $opt_p= '%8%.txt' unless defined $opt_p;
}
if ($opt_f) {
 for (my $fnum= 1; $fnum <= $opt_f; ++$fnum) {
  my($n, $pfx, $sfx, $width);
  if ($opt_p =~ /(.*)%(\d*)%(.*)/) {
   ($pfx, $width, $sfx)= ($1, $2, $3);
  }
  else {
   ($pfx, $width, $sfx)= ($opt_p, 1, '');
  }
  $width= 1 if $width eq '' || $width < 1;
  $n= $opt_n ? sprintf("%0${width}u", $fnum) : genword($width);
  $n= $pfx . $n . $sfx;
  redo if -e $n;
  local *FH;
  open FH, '>', $n or die $!;
  $fh= *FH{IO};
  wrtext;
  close FH or die $!;
 }
}
else {
 $fh= *STDOUT{IO};
 wrtext;
}
