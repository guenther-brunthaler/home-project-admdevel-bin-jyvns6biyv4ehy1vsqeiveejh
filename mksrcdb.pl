# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$

# Creates lookup-databases from source files.
#
# This will allow the following queries:
# * List all duplicates groups with each path name
# * Given a basename, list all duplicates groups with each path name.
# * Given a path name, lists all duplicate path names.
#
# Data structures:
# %dlinks{GROUPS} -> glist
# %dlinks{glist} -> [succ, group0]
# %dbnames{lc basename} -> group0
# %dlinks{group} -> [succ, dup0]
# %dpaths{lc path} -> dup0
# %dlinks{dup} -> [succ, pathname]


my $base_path= 'cvs_bld';
#my $base_path= 'test';


use strict;
use Fcntl qw(:DEFAULT :seek);
use SDBM_File;
use Digest::MD5;
use File::Spec::Functions qw(tmpdir canonpath catfile catdir curdir updir);
use File::Temp qw(mktemp tempfile);
use Cwd;
use FindBin;
use lib "$FindBin::Bin";
use Lib::SetupCMVC_8941443E_7D37_11D6_94FD_009027319575;


our(%dbnames, %dlinks, %dpaths, %bnames, %rbnames, %paths, %rpaths, %links);
our($cnt, $ci, $tmp, $path0, $bname0);


sub process_cd {
   my($base, $ign)= @_;
   local(*DIR, $_);
   opendir DIR, curdir or die;
   my($pid, $bid, $k, $ignoredir);
   $ignoredir= quotemeta(curdir) . '|' . quotemeta(updir);
   $ignoredir= qr/^(?:CVS|RCS|$ignoredir)$|^\./i;
   while ($_= readdir DIR) {
      next if $ign && /\.(?:pag|dir)$/i;
      if (-d) {
         next if /$ignoredir/;
         chdir $_ or die;
         &process_cd(catdir $base, $_);
         chdir updir or die;
      }
      elsif (-f _) {
         # Create/lookup path id.
         if (exists $paths{$k= lc $base}) {
            $pid= $paths{$k};
         }
         else {
            $paths{$k}= $pid= ++$ci;
            $rpaths{$pid}= $base;
            $links{PATHS}= $path0= $pid unless defined $path0;
         }
         # Create/lookup basename id.
         if (exists $bnames{$k= lc}) {
            $bid= $bnames{$k};
         }
         else {
            $bnames{$k}= $bid= ++$ci;
            $rbnames{$bid}= $_;
            $links{BASENAMES}= $bname0= $bid unless defined $bname0;
         }
         # Link basename into list associated with path.
         if (exists $links{$pid}) {
            $links{++$ci}= $links{$pid};
            $links{$pid}= pack 'ww', $ci, $bid;
         }
         else {
            $links{$pid}= pack 'ww', 0, $bid;
         }
         # Link path into list associated with basename.
         if (exists $links{$bid}) {
            $links{++$ci}= $k= $links{$bid};
            $links{$bid}= pack 'ww', $ci, $pid;
            print $tmp $bid, "\t" if unpack('w', $k) == 0;
         }
         else {
            $links{$bid}= pack 'ww', 0, $pid;
         }
         if (++$cnt >= 1000) {
            $cnt= 0;
            print '.';
         }
      }
   }
   closedir DIR or die;
}


sub contents {
   my $fn= shift;
   my $md5= new Digest::MD5;
   local *FH;
   open FH, '<', $fn or die "Cannot open '$fn': $^E";
   $md5->addfile(*FH{FILEHANDLE});
   close FH or die $^E;
   #$md5->hexdigest;
   $md5->digest;
}


sub find_duplicates {
   my($bid, @d, $i, $li, $bn, $di, $groups0);
   local $/= "\t";
   $groups0= 0;
   while ($bid= <$tmp>) {
      chomp $bid;
      $bn= $rbnames{$bid};
      #print "\nbasename '$bn':\n";
      # Get next group of paths containing the same basename.
      @d= ();
      for ($i= $bid; $i; $i= $li->[0]) {
         $li= [unpack 'ww', $links{$i}];
         push @d, [$li->[1]]; # [pid, size, contents]
      }
      # Sort by size, contents. Combine size & contents to a single key.
      @d= map {
         # map to [size . contents, pid]
         [defined($_->[2]) ? $_->[1] . ':' . $_->[2] : $_->[1], $_->[0]]
      } sort {
         $a->[1]= -s catfile $rpaths{$a->[0]}, $bn unless defined $a->[1];
         $b->[1]= -s catfile $rpaths{$b->[0]}, $bn unless defined $b->[1];
         return $a->[1] <=> $b->[1] if $a->[1] != $b->[1];
         unless (defined $a->[2]) {
            $a->[2]= contents catfile $rpaths{$a->[0]}, $bn;
         }
         unless (defined $b->[2]) {
            $b->[2]= contents catfile $rpaths{$b->[0]}, $bn;
         }
         $a->[2] cmp $b->[2];
      } @d;
      #for (my $i= 0; $i < @d; ++$i) {
      # print "mapped \$d[$i] = ["
      # , join(', ', map defined($_) ? $_ : 'undef', @{$d[$i]})
      # , "]\n"
      # ;
      #}
      # Remove non-duplicates.
      for ($i= 0; $i < @d; ) {
         if (
            !($i > 0 && $d[$i]->[0] eq $d[$i - 1]->[0])
            && !($i + 1 < @d && $d[$i]->[0] eq $d[$i + 1]->[0])
         ) {
            splice @d, $i, 1;
            next;
         }
         ++$i;
      }
      #for (my $i= 0; $i < @d; ++$i) {
      # print "only dups \$d[$i] = ["
      # , join(', ', map defined($_) ? $_ : 'undef', @{$d[$i]})
      # , "]\n"
      # ;
      #}
      next if @d == 0;
      # Create duplicate groups.
      unshift @d, [shift @d]; # First group.
      for ($i= 1; $i < @d; ) {
         if ($d[$i - 1]->[-1]->[0] eq $d[$i]->[0]) {
            # Same group.
            push @{$d[$i - 1]}, splice @d, $i, 1;
            next;
         }
         # Next group.
         splice @d, $i, 1, [$d[$i]];
         ++$i;
      }
      # Now: $d[$group]->[$dup]= [$cmpkey, $pid]
      #for (my $j= 0; $j < @d; ++$j) {
      # for (my $i= 0; $i < @{$d[$j]}; ++$i) {
      #  print "only dups \$d[$j][$i] = ["
      #  , join(', ', map defined($_) ? $_ : 'undef', @{$d[$j]->[$i]})
      #  , "]\n"
      #  ;
      # }
      #}
      # Enter everything into database.
      $li= 0;
      foreach my $g (@d) {
         # Write linked duplicate pathnames.
         $di= 0;
         foreach my $dup (@$g) {
            $dlinks{++$ci}= pack 'wa*', $di, catfile $rpaths{$dup->[1]}, $bn;
            $di= $ci;
         }
         # Write path name lookups.
         foreach my $dup (@$g) {
            $dpaths{lc catfile $rpaths{$dup->[1]}, $bn}= pack 'w', $di;
         }
         # Add to group list.
         $dlinks{++$ci}= pack 'ww', $li, $di;
         $li= $ci;
      }
      # Write basename lookup.
      $dbnames{lc $bn}= pack 'w', $li;
      # Add to list of groups.
      $dlinks{++$ci}= pack 'ww', $groups0, $li;
      $groups0= $ci;
      if (++$cnt > 50) {
         print '.';
         $cnt= 0;
      }
   }
   $dlinks{GROUPS}= pack 'w', $groups0;
}


Lib::SetupCMVC;
$base_path= catdir(canonpath($ENV{LOCAL_BUILDTREE_PREFIX}), $base_path);
die $^E unless -d $base_path;
my(@dbs, $olddir);
$tmp= tempfile catfile tmpdir, $$ . ('X' x 10) or die $^E;
{
   my $n= 0;
   foreach (
      map {ref $_ eq 'ARRAY' ? $_ : [$_, 1]} (
         [\%dbnames]
         , [\%dlinks]
         , [\%dpaths]
         , \%bnames, # lc(bname) -> bname id
         , \%paths # lc(path) -> path id
         , \%rpaths # path id -> path
         , \%rbnames # bname id -> bname
         , \%links # pid -> [succ, bid]; bid -> [succ, pid];
      )
   ) {
      $_->[2]
      = $_->[1]
      ? mktemp catfile tmpdir, $$ . ('X' x 8)
      : catfile $base_path, 'mksrcdb' . ++$n
      ;
      tie
            %{$_->[0]}, 'SDBM_File'
            , $_->[2], O_RDWR | O_TRUNC | O_CREAT, 0666
         or
            die "Couldn't tie SDBM file '$_->[2]': $!; aborting"
      ;
      push @dbs, $_;
   }
}
$olddir= cwd or die $^E;
chdir $base_path or die $^E;
print "Scanning directories";
{
   $ci= $cnt= 0;
   local $|= 1;
   process_cd $base_path, 1;
}
print "\n";
chdir $olddir or die $^E;
seek $tmp, 0, SEEK_SET or die;
print "Checking for duplicates";
{
   $ci= $cnt= 0;
   local $|= 1;
   find_duplicates;
}
print "\n";
foreach my $db (@dbs) {
   untie %{$db->[0]};
   if ($db->[1]) {
      foreach (qw/dir pag/) {
         #print "unlinking '$db->[2].$_'\n";
         unlink("$db->[2].$_") == 1 or die $^E;
      }
   }
}
print "Done.\n";
