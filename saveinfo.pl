#! /usr/bin/perl
# Save Infos about argument files into database.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/saveinfo.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Long;
use File::Spec;
use FindBin;
use lib "$FindBin::Bin";
use ExpandFilelist_57D9097A_926F_11D6_951B_009027319575;
use Lib::Add_s_6D696095_CBC0_11D5_9920_C23CC971FBD2;


my %Tools= (
   BitCollider => '%ProgramFiles%\opt\Bitcollider\bitcollider.exe'
   , MD5Sum => '%ProgramFiles%\bin\md5sum.exe'
);


sub EnvCompressPrefix($) {
   my $s= shift;
   $s;
}


sub process(\%$) {
   my($r, $filename)= @_;
   %$r= ();
   {
      my($v, $d, $f)= File::Spec->splitpath(File::Spec->rel2abs($filename));
      my @d= File::Spec->splitdir($d);
      $r->{path_ktx4d9vde2it90dasmf8a9wk6}= EnvCompressPrefix(
         File::Spec->catdir(File::Spec->catpath($v, '', ''), @d)
      );
   }
}


sub store(\%) {
   my $data= shift;
}


sub EnvExpand(\$) {
   my $s= shift;
   $$s =~ s(
      \% ( [^%]* ) \%
   ) (
      length($1) == 0
      ? '%'
      : do {
         unless (exists $ENV{$1}) {
            die "Undefined environment variable '\%$1\%' in '$$s'";
         }
         $ENV{$1};
      }
   )gex;
}


sub cleanup_errmsg(\$) {
   my $v= shift;
   do {
      while (chomp $$v) {}
   } while $$v =~ s/[.!]$//;
}


my($opt_help, $opt_verbose, $opt_quiet, $opt_print);
my $Usage= <<"END";
$0 - save info about files to system-local database

The infos contain checksums, file size, date time, certain MP3 tag properties
fpr MP3 files, version information for executables etc.

Usage: $0 [ options ] file ...
where
'file ...': A list of files to be processed. May include wildcards as well as
            response files specifications ('\@filename').

If reponse files are used, they may contain contain the same contents as
valid for the command line, including wildcards and nested response file
specifications.

options supported:
-p, --print: Print results to standard output instead of putting them into
             the database.
-h, --help: Display this help.
-v, --verbose: Display messages while processing.
-q, --quiet: Don't even display warning/error messages.

Return codes:
0: no errors
1: some files could not be processed
2: database update error
3: invalid command line options or aborted due to fatal errors

$0 has been written in 2003 by Guenther Brunthaler
END
Getopt::Long::Configure('bundling');
GetOptions(
   'h|help' => \$opt_help
   , 'v|verbose' => \$opt_verbose
   , 'q|quiet' => \$opt_quiet
   , 'p|print' => \$opt_print
) or die $Usage;
if ($opt_help) {
   print $Usage;
   exit;
}
eval {
   die $Usage unless @ARGV;
   foreach (values %Tools) {
      EnvExpand $_;
   }
   ExpandFilelist(\@ARGV, -log => $opt_verbose, -expand_globs => 1);
   my $failed= 0;
   my $processed= 0;
   my %data;
   my $ok;
   foreach (@ARGV) {
      print qq'processing file "$_"... ' if $opt_verbose;
      eval {process %data, $_};
      if ($@) {
         cleanup_errmsg $@;
         ++$failed;
         unless ($opt_quiet) {
            print qq'processing file "$_"... ' unless $opt_verbose;
            print "failed: $@\n";
         }
      }
      else {
         unless ($opt_print) {
            eval {store %data};
            if ($@) {
               cleanup_errmsg $@;
               print "Fatal database error: $@.\n";
               exit 2;
            }
         }
         print "ok\n" if $opt_verbose;
         foreach (sort keys %data) {
            print qq!$_="$data{$_}"\n!;
         }
         ++$processed;
      }
   }
   if ($failed && !$opt_quiet) {
      print 'Warning: ', Lib::Add_s($failed, 'file'), ' from a total of '
      , Lib::Add_s(scalar($failed + $processed), 'file')
      , " could not be analyzed!\n"
      ;
   }
   exit 1 if $failed;
   unless ($processed) {
      print "Warning: No matching files found!\n" unless $opt_quiet;
   }
};
if ($@) {
   cleanup_errmsg $@;
   print STDERR $@;
   exit 3;
}
