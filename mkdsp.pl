# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/mkdsp.pl 2647 2006-08-26T07:45:40.216781Z gb  $
#
# Batch make DSP file configurations.


# NLS sync tool relative to %LOCAL_BUILDTREE_PARENTDIR%


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::SetupMSVC_4BCAA36C_7D39_11D6_94FD_009027319575;
use Getopt::Std;


our($opt_t, $opt_m, $opt_f, $opt_p);


sub qin {
 my $s= shift;
 $s =~ /\s/ or return $s;
 '"' . $s . '"';
}


sub xec {
 if ($opt_p) {
  print shift, "\n";
 }
 else {
  system(shift) == 0 or $opt_f ? warn $^E : die $^E;
 }
}


my(@m, $dsp);
$opt_t= 'Release';
getopts('l:t:m:fps') or die <<"END";
Usage: $0 [ <options> ...]
where the following options are supported:
-m <makefile>: specify makefile name; defaults to file that matches '*_res.mak'
-t <maketype>: specify CFG prefix, e. g. "-t Debug"; defaults to 'Release'
-f: force - don't stop on nmake errors
-p: print nmake command lines instead of executing them
END
Lib::SetupMSVC;
if (defined $opt_m) {
 @m= $opt_m;
}
else {
 @m= <*.dsp>;
}
for (my $i= 0; $i < @m; ) {
 print STDERR "Parsing '$m[$i]'...\n";
 if (open IN, '<', $m[$i]) {
  $m[$i]= {name => $m[$i], cfgs => {}};
  while (<IN>) {
   next unless /^!(?i)(?:ELSE)?IF(?-i)\s*"\$\(CFG\)"\s*==\s*"([^"]+)"\s*$/;
   $m[$i]->{cfgs}->{lc $1}= $1
  }
  close IN or die;
  $m[$i]->{cfgs}= [
   sort grep /\s-\sWin32\s$opt_t(?:\s|$)/, values %{$m[$i]->{cfgs}}
  ];
 }
 else {
  $opt_f ? warn $^E : die $^E;
  splice @m, $i, 1;
  next;
 }
 ++$i;
}
@m= sort {$a->{name} cmp $b->{name}} @m;
print "\@ECHO OFF\n" if $opt_p;
foreach my $phase (1 .. 3) {
 foreach (@m) {
  $dsp= $_->{name};
  if ($phase == 1) {
   xec 'REM >' . qin($dsp . '.buildlog');
  }
  foreach (@{$_->{cfgs}}) {
   my $c= qin($_);
   if ($phase == 1) {
    print STDERR "Cleaning up $c of ", qin($dsp), "...\n" unless $opt_p;
    $c= "msdev.exe $dsp /MAKE $c /CLEAN /OUT NUL";
    xec $c;
   }
   elsif ($phase == 2) {
    print STDERR "Building $c of ", qin($dsp), "...\n" unless $opt_p;
    $c= "msdev.exe $dsp /MAKE $c /OUT " . qin($dsp . '.buildlog.tmp');
    xec $c;
    $c= 'TYPE ' . qin($dsp . '.buildlog.tmp')
    . ' >>' . qin($dsp . '.buildlog')
    ;
    xec $c;
   }
  }
  if ($phase == 3) {
   xec 'DEL ' . qin($dsp . '.buildlog.tmp') . ' >NUL';
  }
 }
}
print STDERR "Done.\n";
