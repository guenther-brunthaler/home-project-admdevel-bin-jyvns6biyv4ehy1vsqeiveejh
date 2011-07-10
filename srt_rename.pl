#! /usr/bin/perl
# Rename .srt files in current directory from "XXX.srt"
# into "Movie Name - XXX Subtitles.latin1.srt"
# unless they end already in ".latin1.srt".
#
# Also enforces that "XXX" matches
# "(English|German) (SDH|Director's Comments|Composer's Comments
# |Additional Comments|Translations)"
# and expands abbreviations.
#
# ESL: English as a second Language
# SDH: Subtitles for the deaf and hard of hearing
#
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/srt_rename.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Std;


sub mprefix0 {
   my($s, $min)= @_;
   return '' if $s eq '';
   $min= 1 unless defined $min;
   return $min
      ? quotemeta(substr $s, 0, $min) . ' ' . mprefix0(substr($s, $min), 0)
      : '(?: ' . mprefix0($s) . ' )?'
   ;
}


sub mprefix($;$;$) {
   my($s, $f, $min)= @_;
   $s= mprefix0 $s, $min;
   $s= "(?x$f: $s)" if $f;
   #$s= qr/$s/;
   #print "QR '$s'\n";
   #return $s;
   return qr/$s/;
}


sub ssmprefix($;$;$) {
   my $s= mprefix $_[0], $_[1], $_[2];
   return qr/ \b $s (?= [^[:alpha:]] | $ ) /x;
}


my(%opt);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 2647 $' =~ /(\d[\d.]*)/;
getopts('pvb', \%opt) or die;
eval {
   my(@srt, $i, $mn);
   {
      my(@mn);
      {
         my %mn;
         opendir DIR, '.' or die "Cannot list directory: $!";
         while (defined($_= readdir DIR)) {
            if (/\.srt$/i && !/\.latin1\.srt$/i) {
               push @srt, $_;
            }
            elsif (/\.d2v$/i) {
               s/\s*\.d2v$//i;
               s/
                  , \s*
                  (?: German | English )
                  (?: , \s* Audio \s* \d+ \s* \w+)*
                  \s* \)
               /)/ix;
               $mn{$_}= 1;
            }
         }
         closedir DIR or die;
         @mn= sort keys %mn;
      }
      print "Select Basic Movie Name (Language Independent):\n";
      for ($i= 0; $i < @mn; ++$i) {
         print $i + 1, '.) ', $mn[$i], "\n";
      }
      print $i + 1, ".) [Enter name manually]\n";
      {
         local $|= 1;
         print "\nYour Choice? ";
         $_= <STDIN>; chomp;
         if (!/^\d+$/ || $_ < 1 || --$_ > $i) {
            die "Aborted";
         }
         if ($_ == $i) {
            print "\nEnter movie name? ";
            $mn= <STDIN>; chomp $mn;
            die "Aborted" if $mn =~ /^\s*$/;
         }
         else {
            $mn= $mn[$_];
         }
      }
   }
   $mn =~ s/ ^\s* | \s*$ //xg;
   print "Selected movie name is '$mn'\n" if $opt{v};
   my($old, $new, $s, $n);
   $n= 0;
   foreach (sort {lc $a cmp lc $b} @srt) {
      $old= $_;
      s/\s*\.srt$//i;
      ?^? or $s= '';
      ?^? and $s= ssmprefix "English", 'i';
      s/$s/English/o;
      ?^? and $s= ssmprefix "German", 'i';
      s/$s/German/o;
      ?^? and $s= ssmprefix "Deutsch", 'i';
      s/$s/German/o;
      ?^? and $s= ssmprefix "Director's Comments", 'i', 2;
      s/$s/Director's Comments/o;
      ?^? and $s= ssmprefix "Composer's Comments", 'i', 2;
      s/$s/Composer's Comments/o;
      ?^? and $s= ssmprefix "SDH", 'i', 2;
      s/$s/SDH/o;
      ?^? and $s= ssmprefix "Translations", 'i', 7;
      s/$s/Translations/o;
      ?^? and $s= ssmprefix "Transl8ions", 'i', 2;
      s/$s/Translations/o;
      ?^? and $s= ssmprefix "XL8s", 'i', 3;
      s/$s/Translations/o;
      ?^? and $s= ssmprefix "XLations", 'i', 3;
      s/$s/Translations/o;
      ?^? and $s= ssmprefix "Additional Comments", 'i', 3;
      s/$s/Additional Comments/o;
      s/
         ^
         (English | German) \d*
         (
            (?:
               [ ] (
                  SDH
                  | (?: Director | Composer ) \'s [ ] Comments
                  | Additional [ ] Comments
                  | Translations
               )
            )?
         )
         $
      /$1$2/x
         or warn("Cannot process bad name '$_'"), next
      ;
      $new= "$mn - $_ Subtitles.latin1.srt";
      if ($opt{b}) {
         print qq!REN "$old" "$new"\n!;
         ++$n;
      }
      else {
         print "renaming '$old' into '$new'...\n" if $opt{v};
         rename $old, $new
            or warn "Could not rename '$old' into '$new': $!"
         ;
         ++$n;
      }
   }
   print "$n file name(s) have successfully been processed.\n";
};
print STDERR $@ if $@;
if ($opt{p}) {
   local $|= 1;
   print "\nPlease press [Enter] now to complete execution! ";
   <STDIN>;
}
