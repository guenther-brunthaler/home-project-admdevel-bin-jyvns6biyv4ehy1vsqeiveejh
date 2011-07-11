#! /usr/bin/perl -w
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=RplcRX$
# Extended string replacement tool for text or binary files.
# $xsa2:description$
# This tool allows to search for text files that match certain filenames
# and/or certain file contents in a directory and its subdirectories.
#
# The matching text sections can then be replaced by an expression
# that may include tagged portions out of the matching string.
#
# This tool will ONLY search text files it has special built-in heuristics
# in order to determine whether a file is a text file or not.
#
# So, even if no file mask is defined (meaning 'match all files'), then
# no binary files will be searched if present.
#
# The above does not apply for binary file operation mode.
#
# The tool allows to use either simple text strings or powerful PERL
# regular expressions as match criteria.
#
# In short, in unleashes the full power of Perl regular expression
# substitution at the hand of the user.
# $xsa2:end$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Tk;
use Tk::Dialog;
use Lib::TOOLS::SettingsFile_6D69609F_CBC0_11D5_9920_C23CC971FBD2;
use Lib::ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;
use Lib::Add_s_6D696095_CBC0_11D5_9920_C23CC971FBD2;


{
   package OverlappedReader;
   # Read a file as sequences of two block.
   # UUID {AA5FDE35-958E-11D6-9520-009027319575}.
   our $VERSION= '1.00';


   # Instance variables:
   # Prefix is 'de35_'.
   # $self->{de35_fh}.


   sub new {
      my($self, $fh)= @_;
      $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
      $self->{de35_fh}= $fh;
      $self;
   }


}


my(%opt, $rf, $out, $in, $cf, $cs, $sz);
Lib::TOOLS::SettingsFile::Process(
   -source => \@ARGV,
   -target => \%opt,
   -window_title => 'PERL RegEx replacement search tool',
   -headline => 'Text File Search & Replacement Tool',
   -do_button => 'RplcRX',
   -options => [
      '--settingsfile' => 'name of file where to store/retrieve settings',
      '--startdir' => 'directory where to start search',
      '--globreg' => 'regular expression for file/pathname matching',
      '--xglobreg' => 'regular expression for file/pathname exclusion matching',
      '--glob' => 'substring for file/pathname matching (no wildcards supported)',
      '--search_reg' => 'regular expression for file contents matching',
      '--reject_reg' => 'regular expression for line match rejection matching',
      '--search_pat'
      => 'substring for file contents matching (no wildcards supported)'
      ,
      '--rplc_string' => 'simple text string for replacement',
      '--rplc_expr'
      => 'text string containing $1, $2, \n, \t etc. for variables/specials'
      ,
      '--interactive' => 'ask user before doing replacements',
      '--create_copies'
      => "create files with '.new' added instead of replacing originals"
      ,
      '--repeat_subst'
      => 'repeat substitution in line as long as pattern matches'
      , '--gui' => 'uses GUI to query/edit parameters if option value <> 0'
      , '--binary' => 'operate on binary files, disable text file autodetection'
      , '--max_size' => 'maximum byte size for files to be selected'
      , '--first_only' => 'substitute only the first match (not globally)'
   ]
);
$opt{startdir}= exists $opt{startdir} ? '"'. $opt{startdir} . '"' : '';
$opt{globreg}= '.*' if !exists($opt{globreg}) && !exists($opt{glob});
if (exists $opt{glob}) {
   $opt{globreg}= ($^O =~ /Win32/ ? '(?i)' : '') . quotemeta($opt{glob});
}
$opt{globreg}= qr/$opt{globreg}/;
if (!exists($opt{search_reg}) && !exists($opt{search_pat})) {
   die "Either --search_reg or --search_pat must be specified"
}
if (exists $opt{search_pat}) {
   $opt{search_reg}= quotemeta $opt{search_pat} ;
}
$opt{search_reg}= qr/$opt{search_reg}/;
if (!exists $opt{rplc_string} && !exists $opt{rplc_expr}) {
   die "Either --rplc_string or --rplc_expr must be specified";
}
if (exists $opt{rplc_string}) {
   $opt{rplc_expr}= quotemeta $opt{rplc_string};
}
if ($opt{interactive}) {
   $opt{interactive}= MainWindow->new(qw/-width 1 -height 1/);
}
foreach (qw/xglobreg reject_reg/) {
   next unless exists $opt{$_};
   $opt{$_}= qr/$opt{$_}/;
}
$opt{first_only}= exists $opt{first_only} ? '' : 'g';
open FILES
, $opt{binary}
? q!perl -MFile::Find -e "!
. q!find sub{print qq'$File::Find::name\\n' if -f $_ && -r _}!
. q!, @ARGV ? @ARGV : '.'"!
. qq! $opt{startdir} |!
: qq'perl "$FindBin::Bin/find_txt_files.pl" $opt{startdir} |'
or die
;
$rf= new Lib::ReplacementFile;
$cf= $cs= 0;
while (<FILES>) {
   chomp;
   next if exists $opt{xglobreg} && /$opt{xglobreg}/;
   next unless /$opt{globreg}/;
   $sz= -s if defined $opt{maxsize} || defined $opt{binary};
   next if defined $opt{maxsize} && $sz > $opt{maxsize};
   my($fn, $ok, $dlg, $o, $r);
   unless (open FILE, '<', $fn= $_) {
      warn qq'Cannot open file "$fn" for reading\n';
      next;
   }
   $ok= 0;
   for (;;) {
      if ($opt{binary}) {
         binmode FILE or die;
         my $r= read FILE, $_, $sz;
         last if $r == 0;
         unless (defined $r && $r == $sz) {
            warn "Read error: $!";
            last;
         }
      }
      else {
         last unless defined($_= <FILE>);
      }
      last if $ok
      = (!exists $opt{reject_reg} || !/$opt{reject_reg}/)
      && /$opt{search_reg}/
      ;
   }
   close FILE or die;
   next unless $ok;
   ($out, $in)= $rf->create(
      -original_name => $fn, qw/-warn 1/, -emulate => $opt{create_copies}
   );
   next unless defined $out;
   $ok= 0;
   for (;;) {
      if ($opt{binary}) {
         binmode $in or die;
         my $r= read $in, $_, $sz;
         last if $r == 0;
         unless (defined $r && $r == $sz) {
            warn "Read error: $!";
            last;
         }
      }
      else {
         last unless defined($_= <$in>);
      }
      if (
         (!exists $opt{reject_reg} || !/$opt{reject_reg}/)
         && /$opt{search_reg}/
      ) {
         $o= $_;
         eval "while ("
         . "s/\$opt{search_reg}/$opt{rplc_expr}/$opt{first_only} "
         . "&& \$opt{repeat_subst}"
         . ") {}"
         ;
         ++$cs;
         ++$ok;
         if (!$opt{binary} && exists $opt{interactive}) {
            $dlg= $opt{interactive}->Dialog(
               -title => 'Search pattern matches',
               -text => "Replace string\n\n$o\n\nby string\n\n$_\n\nin file '$fn'?",
               -buttons => ['Find Next', 'Replace', 'Replace All', 'Abort'],
               qw/-bitmap question -default_button Replace/
            );
            $dlg= $dlg->Show;
            exit if $dlg eq 'Abort';
            if ($dlg eq 'Replace All') {
               delete $opt{interactive};
            }
            elsif ($dlg eq 'Find Next') {
               $_= $o; --$ok; --$cs;
            }
         }
      }
      print $out $_;
   }
   $ok and $rf->commit, ++$cf or $rf->rollback;
}
close FILES or die;
print
$opt{binary}
? (
   Lib::Add_s($cs, qw/replacement -add has -addpl have/)
   . " been made"
)
: (
   Lib::Add_s($cs, qw/line -add has -addpl have/)
   . " been replaced"
)
, " in ", Lib::Add_s($cf, 'file'), ".\n"
;
