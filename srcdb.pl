#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$

# Creates lookup-databases from source files.


my $base_path= 'cvs_bld';
#my $base_path= 'test';


use strict;
use Getopt::Std;
use Fcntl qw(:DEFAULT);
use SDBM_File;
use File::Spec::Functions qw(canonpath catfile catdir);
use FindBin;
use lib "$FindBin::Bin";
use Lib::SetupCMVC_8941443E_7D37_11D6_94FD_009027319575;


our($opt_t);
our(%dbnames, %dlinks, %dpaths);


die <<"END" unless getopts('t');
Usage: $0 [options ...] [<filespec> ...]
where
<filespec>: A list of basenames, fully qualified path names or response
            file specifications.
Response files are specified by prefixing a file name with "\@"; the
contents of all response files are read line by line and the contents
will considered as if they had been given on the command line.

If <filespec> is missing, all duplicates in all directories will be reported.

options:
-t: print title headings.
END
for (my $i= 0; $i < @ARGV; ) {
   if ($ARGV[$i] =~ /^\@\s*(.+)/) {
      splice @ARGV, $i, 1;
      open RESP, '<', $1 or die $^E;
      while (<RESP>) {
         chomp;
         splice @ARGV, $i, 0, $_;
         ++$i;
      }
      close RESP or die;
      next;
   }
   ++$i;
}
Lib::SetupCMVC;
$base_path= catdir(canonpath($ENV{LOCAL_BUILDTREE_PREFIX}), $base_path);
die $^E unless -d $base_path;
my(@dbs);
{
   my $n= 0;
   foreach (\%dbnames, \%dlinks, \%dpaths) {
      my $name= catfile $base_path, 'mksrcdb' . ++$n;
      tie %$_, 'SDBM_File', $name, O_RDONLY, 0666 or
         die "Couldn't tie SDBM file '$name!; aborting"
      ;
      push @dbs, $_;
   }
}
print join "\t", qw/BNAME VAR DUP PATH/, "\n" if $opt_t;
if (@ARGV == 0) {
   my($glist, $gn, $sg, $dn, $grp, $dup, $pathname);
   $glist= unpack 'w', $dlinks{GROUPS};
   for ($gn= 1; $glist; ++$gn) {
      ($glist, $grp)= unpack 'ww', $dlinks{$glist};
      for ($sg= 1; $grp; ++$sg) {
         ($grp, $dup)= unpack 'ww', $dlinks{$grp};
         for ($dn= 1; $dup; ++$dn) {
            ($dup, $pathname)= unpack 'wa*', $dlinks{$dup};
            print "$gn\t$sg\t$dn\t$pathname\n";
         }
      }
   }
}
else {
   my($glist, $gn, $sg, $dn, $grp, $dup, $pathname, $mult, $k);
   $mult= @ARGV > 1;
   foreach (@ARGV) {
      if (exists $dbnames{$k= lc}) {
         $grp= unpack 'w', $dbnames{$k};
         for ($sg= 1; $grp; ++$sg) {
            ($grp, $dup)= unpack 'ww', $dlinks{$grp};
            for ($dn= 1; $dup; ++$dn) {
               ($dup, $pathname)= unpack 'wa*', $dlinks{$dup};
               print "\t$sg\t$dn\t$pathname\n";
            }
         }
      }
      elsif (exists $dpaths{$k}) {
         $dup= unpack 'w', $dpaths{$k};
         for ($dn= 1; $dup; ++$dn) {
            ($dup, $pathname)= unpack 'wa*', $dlinks{$dup};
            print "\t\t$dn\t$pathname\n";
         }
      }
   }
}
foreach (@dbs) {
   untie %$_;
}
