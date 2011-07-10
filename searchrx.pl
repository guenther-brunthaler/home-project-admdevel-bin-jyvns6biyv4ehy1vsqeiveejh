#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=SearchRX$
# Extended search tool for text files.
# $xsa2:description$
# This tool allows to search for text files that match certain filenames
# and/or certain file contents in a directory and its subdirectories.
# This tool will ONLY search text files - it has special built-in heuristics
# in order to determine whether a file is a text file or not.
# So, even if no file mask is defined (meaning 'match all files'), then
# no binary files will be searched if present.
#
# The tool allows to use either simple text strings or powerful PERL
# regular expressions as match criteria.
#
# It can be started either by using command line parameters
# or via GUI. It is also possible to edit command line parameters in the GUI.
# Reading and writing settings files is also supported.
#
# As an additional bonus, the output of the tool is exactly in the same
# format as required for Microsoft Developer Studio in order to display
# the matching lines when used as a user-defined add-in tool. 
# $xsa2:end$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::TOOLS::SettingsFile_6D69609F_CBC0_11D5_9920_C23CC971FBD2;


my(%opt);
Lib::TOOLS::SettingsFile::Process(
 -source => \@ARGV,
 -target => \%opt,
 -window_title => 'PERL RegEx file search tool',
 -headline => 'PERL RegEx file search tool',
 -do_button => 'SearchRX',
 -options => [
  '--settingsfile' => 'name of file where to store/retrieve settings',
  '--startdir' => 'directory where to start search',
  '--globreg' => 'regular expression for file/pathname matching',
  '--xglobreg' => 'regular expression for file/pathname exclusion matching',
  '--glob' => 'substring for file/pathname matching (no wildcards supported)',
  '--reg' => 'regular expression for file contents matching',
  '--xreg' => 'regular expression for line match rejection matching',
  '--pat' => 'substring for file contents matching (no wildcards supported)',
  '--gui' => 'uses GUI to query/edit parameters if option value <> 0',
  '--binary' => 'do not exclude files from the search that non-text binary data'
 ]
);
$opt{startdir}= exists $opt{startdir} ? '"'. $opt{startdir} . '"' : '';
$opt{globreg}= '.*' if !exists($opt{globreg}) && !exists($opt{glob});
if (exists $opt{glob}) {
 $opt{globreg}= ($^O =~ /Win32/ ? '(?i)' : '') . quotemeta($opt{glob});
}
$opt{globreg}= qr/$opt{globreg}/;
$opt{reg}= '.*' if !exists($opt{reg}) && !exists($opt{pat});
$opt{reg}= quotemeta($opt{pat}) if exists $opt{pat};
$opt{reg}= qr/$opt{reg}/;
foreach (qw/xglobreg xreg/) {
 next unless exists $opt{$_};
 $opt{$_}= qr/$opt{$_}/;
}
open FILES
, $opt{binary}
? q!perl -MFile::Find -e "!
. q!find sub{print qq'$File::Find::name\\n' if -f $_ && -r _}!
. q!, @ARGV ? @ARGV : '.'"!
. qq! $opt{startdir} |!
: qq'perl "$FindBin::Bin/find_txt_files.pl" $opt{startdir} |'
or die
;
while (<FILES>) {
 chomp;
 next if exists $opt{xglobreg} && /$opt{xglobreg}/;
 next unless /$opt{globreg}/;
 my $fn;
 unless (open FILE, '<', $fn= $_) {
  warn qq'Cannot open file "$fn"\n';
  next;
 }
 while (<FILE>) {
  if (
   (!exists $opt{xreg} || !/$opt{xreg}/)
   && /$opt{reg}/
  ) {
   print qq'$fn($.):$_';
  }
 }
 close FILE or die;
}
close FILES or die;
