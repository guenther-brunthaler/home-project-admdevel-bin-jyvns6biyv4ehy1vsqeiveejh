# Replace common misspellings in 'SubRip' OCR-processed
# '*.srt' subtitles files.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/srt_spellfix.pl 2647 2006-08-26T07:45:40.216781Z gb  $.


use strict;
my %subst= (
   # Format: Wrong spelling, correct spelling
   'German', << '.'
      Lan Ian
      Lch Ich
      Lhm Ihm
      Lhn Ihn
      Lhnen Ihnen
      Lhr Ihr
      Lhre Ihre
      Lhrem Ihrem
      Lhren Ihren
      Lhrer Ihrer
      Lhres Ihres
      Lm Im 
      Lmmerhin Immerhin 
      Ln In
      Lntercom Intercom
      Lnternet Internet
      lV IV
      lX IX
      lan Ian
      lch Ich
      lhm Ihm
      lhn Ihn
      lhnen Ihnen
      lhr Ihr
      lhre Ihre
      lhrem Ihrem
      lhren Ihren
      lhrer Ihrer
      lhres Ihres
      ll II
      lll III
      lm Im
      lmperator Imperator
      lmperium Imperium
      ln In
      Ml6 MI6
      ÖI Öl
.
   ,  'English', << '.'
      Lmmediately Immediately
      Ln In
      Lntercom Intercom
      Lnternet Internet
      l've I've
      lV IV
      lX IX
      lan Ian
      ll II
      lll III
      lmperial Imperial
      ln In
      lvory Ivory
      Ml6 MI6
.
   # Special map: Two words that should be written together
   ,  '__CONCAT__', << '.'
   BO Y
   Can 't
   Didn 't
   Don 't
   Hadn 't
   Shouldn 't
   Wasn 't
   Won 't
   Wouldn 't
   can 't
   didn 't
   don 't
   hadn 't
   shouldn 't
   wasn 't
   won 't
   wouldn 't
.
);


use Lib::ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;
use Getopt::Std;


my(%opt);


foreach (values %subst) {
   chomp;
   $_= {
      map {
         /^\s*(\S+)\s+(\S+)\s*$/ or die;
         $1, $2;
      } split /\n/
   };
}
#use Data::Dumper; print Dumper(%subst); exit;
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 2647 $' =~ /(\d[\d.]*)/;
getopts('Nhvq', \%opt) && !$opt{h} && @ARGV == 0 or die << "EGASU";
$0: Replace common misspellings
in 'SubRip' OCR-processed '*.srt' subtitles files.

Searches the current directory for '*.srt'-files matching the
following file name syntax (EBNF):

<filename> ::= <movie_name> " - " <type> " Subtitles.latin1.srt"
<type> ::= <language> ( " " <purpose> )?
<language> ::= "English" | "German"
<purpose> ::= "SDH" | "Director's Comments" | "Composer's Comments"
              | "Additional Comments" | "Translations"
and <movie_name> is the variable part containing the movie name.

Usage: $0 [options]

-h: Display this help.
-v: Be verbose.
-N: creates new files with extension ".new" instead of updating the originals.
-q: Be quiet, do not even display the final statistics.

Version $VERSION
EGASU
$opt{v}&&= !$opt{q};
my($lang, $rf, $in, $out, $rp, $ccat, $tr, $lr, $nf, $cf);
$rf= new Lib::ReplacementFile;
$ccat= $subst{'__CONCAT__'};
my $nwc= '\s:!,\/;."[\])?°';
my $wc= qr/[^$nwc]/;
$nwc= qr/[$nwc]/;
my $bws= qr/ (?: (?<= $nwc ) | ^ ) /xo; # Boundary at start of word.
my $bwe= qr/ (?: (?= $nwc ) | $ ) /xo; # Boundary at end of word.
# Number of changed/total files, total/local replacements.
$cf= $nf= $tr= $lr= 0;
opendir DIR, '.' or die $!;
while (defined($_= readdir DIR)) {
   next unless -f && /
      [ ]-[ ]
      ( [[:alpha:]]+ )
      (?:
         [ ]
         (?:
              SDH | Director's[ ]Comments | Composer's[ ]Comments
            | Additional[ ]Comments | Translations
         )
      )?
      [ ] Subtitles \. latin1 \. srt $
   /x;
   if (exists $subst{$lang= $1}) {
      ++$nf;
      ($out, $in)= $rf->create(-original_name => $_, -emulate => $opt{N});
      if ($opt{v}) {
         print "Processing '$_'..."; {local $|= 1; print ''}
      }
      $lang= $subst{$lang};
      $lr= 0;
      while (defined($_= <$in>)) {
         s!
            $bws # Boundary at start of word.
            ($wc+?) # The word to be checked.
            $bwe # Boundary at end of word.
         !
            defined($rp= $lang->{$1}) # Word is in the replacement dictionary?
            ? do {++$lr; $rp} # Yes, replace it.
            : $1 # No, use original.
         !gexo;
         s!
            $bws # Boundary at start of fist word.
            ( # $1 is the whole match ($2 including the following WS).
               ($wc+) # First word $2 without following WS.
               \s+ # Followed by WS sequence.
            )
            (?=
               # The above only matches if this follows:
               (\$wc+?) # Second word $3.
               $bwe # Boundary at end of second word.
            )
         !
                  ($rp= $ccat->{$2}) # Word is in the __CONCAT__ dictionary.
               && $rp eq $3 # Following word is also registered there.
            ? do {++$lr; $2} # Yes, use word only without the trailing WS.
            : $1 # No, keep word with trailing WS.
         !gexo;
         print $out $_;
      }
      if ($lr) {
         $rf->commit;
         ++$cf;
         print ' ', $lr if $opt{v};
         $tr+= $lr;
      } else {
         print ' no' if $opt{v};
      }
      print " changes.\n" if $opt{v};
   } else {
      warn "Skipping '$_' using unsupported language '$lang'...\n";
   }
}
closedir DIR or die;
unless ($opt{q}) {
   print "$tr changes have been made in $cf out of $nf processed files.\n";
}
