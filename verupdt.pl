#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::XSA_8AEE1C25_CBA0_11D5_9920_C23CC971FBD2;


my $analyze_max= 1000;
my $emulate= 0;


my($i, $st, $fn, $fnb, $prefix, $postfix, $xsa, $path);


while ($fn= <>) {
 chomp $fn;
 next if $fn =~ /\.bak$/;
 next unless -w $fn;
 eval {
  next unless open ORIG, '<', $fn;
  $xsa= new Lib::XSA;
  $xsa->set(
   -filter => ['1={FBF02760-95CF-11D3-BD96-0040C72500FD}', ''],
   -in => *ORIG{IO}
  );
  undef $st;
  for ($i= $analyze_max; $xsa->read; ) {
   if ($xsa->is_mark) {
    if (defined $xsa->filtered_mark) {
     $st= 1;
     last;
    }
   }
   elsif (substr($xsa->get_text, -1) eq "\n") {
    last if --$i <= 0;
   }
  }
 };
 if ($@) {
  die "Error in file '$fn': $@";
 }
 if ($st) {
  seek ORIG, 0, 0;
  $fnb= $fn . '.bak';
  open BAK, '+>', $fnb or die;
  print BAK while defined($_= <ORIG>);
  seek BAK, 0, 0;
 }
 close ORIG;
 if ($st) {
  open ORIG, '>', $fn . ($emulate ? '.new.bak' : '') or die;
  eval {
   $xsa= new Lib::XSA;
   $xsa->set(
    -filter => ['1={FBF02760-95CF-11D3-BD96-0040C72500FD}', ''],
    -in => *BAK{IO}, -out => *ORIG{IO}
   );
   $prefix= '';
   OUTER: while ($xsa->read) {
    if (defined $xsa->filtered_update_mark) {
     if ($xsa->is_new_guid && !defined $xsa->get_shortcut) {
      $xsa->define_shortcut_preferred_or_current_or_automatic;
     }
     #our $seq;
     #print "$seq\n" if $seq >= 0;
     #if ($seq == -1) {
     # print "HERE";
     #}
     #++$seq;
     # Scan line containing opening mark.
     $xsa->write;
     for ($postfix= ''; substr($postfix, -1) ne "\n"; ) {
      last OUTER unless defined $xsa->read;
      unless (defined $xsa->filtered_update_mark) {
       $postfix= $xsa->get_text;
      }
      $xsa->write;
     }
     # Skip until end of line containing closing mark.
     do {
      last OUTER unless defined $xsa->read;
     } until defined $xsa->filtered_update_mark;
     do {
      last unless defined $xsa->read;
     } until !$xsa->is_mark && substr($xsa->get_text, -1) eq "\n";
     # Determine keywords to use.
     $path= $fn;
     $path =~ s/[^:\/\\]*$//;
     $i= 'OTHER';
     if (-f $fn . ',v') {
      $i= 'RCS';
     }
     elsif (-f $path . 'vssver.scc') {
      $i= 'VSS';
     }
     elsif (-d $path . 'RCS') {
      $i= 'RCS';
     }
     elsif (-d $path . 'CVS') {
      $i= 'CVS';
     }
     warn "Using default SCCS entries for '$fn'!\n" if $i eq 'OTHER';
     $i= 'RCS' if $i eq 'CVS';
     $i= ${{
      VSS => [qw/Archive Author Modtime Date Revision Nokeywords/],
      RCS => [qw/RCSfile Revision Date Author State/],
      OTHER => [qw/Revision Date Author/]
     }}{$i};
     # Write new lines.
     foreach (@$i) {
      $xsa->set_text($prefix . '$' . $_ . '$' . $postfix);
      $xsa->write;
     }
     # Create termination mark.
     $xsa->set_text($prefix);
     $xsa->write;
     $xsa->new_mark;
     $xsa->set_guid('{FBF02760-95CF-11D3-BD96-0040C72500FD}');
     $xsa->set_defined_shortcut;
     $xsa->write;
     $xsa->set_text($postfix);
    }
    elsif ($xsa->mark_follows) {
     $prefix= $xsa->get_text;
    }
    else {
     $prefix= '';
    }
    $xsa->write;
   }
  };
  $st= $@;
  close BAK or die;
  close ORIG or die;
  if ($st) {
   unless ($emulate) {
    unlink $fn;
    rename $fnb, $fn;
   }
   die "file $fn: $st";
  }
 }
}
