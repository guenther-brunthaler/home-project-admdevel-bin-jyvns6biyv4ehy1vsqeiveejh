#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=UUID Filename Verifier$
# Verifies that all UUIDs in a set of files are different.
# $xsa2:description$
# This tool scans a directory for a specified file pattern and checks
# all matching files.
#
# The parts of the file name before the file name extension must end
# with an UUID where the curly braces have been omitted.
#
# The tool checks that the UUIDs are present and valid, and also that
# no UUID is used more than once in the names of different files.
#
# Finally it reports the number of UUIDs/files found.
# $xsa2:end$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::SplitFilenameUUID_6D696096_CBC0_11D5_9920_C23CC971FBD2;
use Lib::TOOLS::SettingsFile_6D69609F_CBC0_11D5_9920_C23CC971FBD2;


my(%opt, $u, %u, $f, $nf, $np);
Lib::TOOLS::SettingsFile::Process(
 -source => \@ARGV,
 -target => \%opt,
 -window_title => 'UUID Filename Verifier',
 -headline => 'Filename UUID Uniqueness Verifier',
 -do_button => 'Verify',
 -options => [
  '--settingsfile' => 'name of file where to store/retrieve settings',
  '--gui' => 'uses GUI to query/edit parameters if option value <> 0',
  '--dir' => 'directory containing the files to be verifed',
  '--regpat' => 'regular expression pattern for filename selection'
 ]
);
$opt{dir} =~ s![\\/:.]*$!!;
opendir DIR, $opt{dir} or die;
$opt{dir} =~ s!(.+)!$1/!;
$opt{regpat}= qr/$opt{regpat}/;
$nf= $np= 0;
while ($f= readdir DIR) {
 next unless $f =~ $opt{regpat};
 $f= $opt{dir} . $f;
 ++$nf;
 eval {$u= (Lib::SplitFilenameUUID $f)[2]};
 if ($@) {
  $@ =~ s/\s*$//;
  print "$@!\n";
  ++$np;
  next;
 }
 if (exists $u{$u}) {
  print "File '$f' has same UUID as file '$u{$u}'!\n";
  ++$np;
 }
 else {
  $u{$u}= $f;
 }
}
closedir DIR or die;
print "$np problems have been found in $nf selected files.\n";
