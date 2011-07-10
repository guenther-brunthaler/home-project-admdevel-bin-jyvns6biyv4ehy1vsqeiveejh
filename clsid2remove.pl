#! /usr/bin/perl
# Process a registry script and change all
# HKEY_CLASSES_ROOT\CLSID|Interface|TypeLib
# sections into key-removal sections.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/clsid2remove.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Std;
use ReplacementFile_F467BD49_CBA4_11D5_9920_C23CC971FBD2;


my(%opt, $tpl);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 2647 $' =~ /(\d[\d.]*)/;
unless (getopts('n', \%opt) && @ARGV > 0) {
   die
        "Usage: $0 [ <options> ] <file1>.reg ...\n"
      . "options:\n"
      . "-n: create new files instead of modifying the current ones.\n"
}
my $wf= new Lib::ReplacementFile;
foreach my $file (@ARGV) {
   my($out, $in)= $wf->create(-original_name => $file, -emulate => $opt{n});
   undef $tpl;
   while (defined($_= <$in>)) {
      if (/ ^ \[ /x) {
         # A key.
         if (
            /
               ^ \[ HKEY_CLASSES_ROOT
               \\ ( (?: CLSID | Interface | TypeLib)
               \\ \{ [-[:xdigit:]]{36} ) }
            /xi
         ) {
            # A reduction key.
            unless ($tpl && $tpl eq $1) {
               # The first or a different reduction key.
               $tpl= $1;
               s/ ^ \[ ( .*? } ) .* /[-$1\n/x;
               print $out $_;
            }
         } else {
            # A key, but no reduction key.
            undef $tpl;
            print $out $_;
         }
      } else {
         # A value.
         print $out $_ unless $tpl;
      }
   }
   $wf->commit;
}
