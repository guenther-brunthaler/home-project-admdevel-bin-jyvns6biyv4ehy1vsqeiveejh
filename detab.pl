# Expand tabs.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/detab.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Getopt::Long;
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;
use ExpandFilelist_57D9097A_926F_11D6_951B_009027319575;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';


my($tab_width, $verbose, $filter, $summary, $make_backups);
my $Usage= <<"END";
Usage: $0 (--help | -h)
Usage: $0 [options] <file> ...
where
<file> ...: list of files or '-' for filter mode.
In filter mode, standard input is tab-expanded to standard output.
File list can contain shell jokers and response files in the format \@filelist,
where <filelist> is a text file containing a list of filenames, separated
by whitespace or newline characters. File names containing whitespaces
must be quoted using double quotes.

Options:
--summary, -s: display summary information only
--tab-width <n>, -t <n>: specify tab width, defaults to 8
--verbose, -v: display information on files while they are processed
--make-backups, --backup, -b: make backups of changes files.
--help, -h, -?: display this help

Version $VERSION
written by Guenther Brunthaler in 2002
END


sub log {
   my($msg, $force)= @_;
   my($fh);
   return unless $verbose || $force;
   $fh= $filter ? *STDERR{FILEHANDLE} : *STDOUT{FILEHANDLE};
   print $fh $msg;
}


# Returns undef if no useful tab expansions have been made.
sub expand_tabs {
   my($in, $out)= @_;
   my($line, $any, $i);
   while (defined($line= <$in>)) {
      while (($i= index $line, "\t") >= 0) {
         # Replace leading tab at position <$i>.
         substr($line, $i, 1)=
            ' ' x (int($i / $tab_width + 1) * $tab_width - $i)
         ;
         $any= 1;
      }
      print $out $line;
   }
   $any;
}


Getopt::Long::Configure("bundling");
$tab_width= 8;
$make_backups= 1;
exit unless GetOptions(
   'h|?|help' => sub {
      print $Usage;
      die "stopped";
   },
   'tab-width|t=i' => \$tab_width,
   'verbose|v' => \$verbose,
   'summary|s' => \$summary,
   'make-backups|backup|b' => \$make_backups,
   '' => \$filter
);
my $files= 0;
if ($filter) {
   &log("Filtering from standard input to standard output...\n");
   expand_tabs(*STDIN{FILEHANDLE}, *STDOUT{FILEHANDLE});
   $files= 1;
}
else {
   ExpandFilelist(\@ARGV, -expand_globs => $^O =~ /Win32/, -log => \&log);
   foreach my $fname (@ARGV) {
      next unless -f $fname;
      unless (-r _ && -w _) {
         warn "skipping '$fname'...\n";
         next;
      }
      &log("Processing file '$fname'...\n");
      my($err, $tmpname, $any)= $fname;
      $tmpname =~ s/(.*?)\.*$/~$1~$$.tmp/;
      unless (open IN, '<', $fname) {
         warn "cannot open '$fname'; skipping...\n";
         next;
      }
      open OUT, '>', $tmpname or die;
      eval {
         $any= expand_tabs(*IN{FILEHANDLE}, *OUT{FILEHANDLE});
      };
      $err= !!$@;
      close OUT or die;
      close IN or die;
      if ($err) {
         unlink $tmpname;
         die;
      }
      if ($any) {
         my ($bakname);
         $bakname= $fname;
         $bakname =~ s/(.*?)\.*$/$1.bak/;
         if (-e $bakname) {
            unlink($bakname) == 1 or
               die "Cannot remove old backup file '$bakname'"
            ;
         }
         rename $fname, $bakname or
            die "Cannot rename '$fname' into '$bakname'"
         ;
         rename $tmpname, $fname or
            die "Cannot rename '$tmpname' into '$fname'"
         ;
         if (!$make_backups) {
            unlink($bakname) == 1 or
               die "Cannot remove backup file '$bakname'"
            ;
         }
         ++$files;
      }
      else {
         unlink $tmpname;
      }
   }
}
&log("$files file(s) have been processed.\n", 1);
