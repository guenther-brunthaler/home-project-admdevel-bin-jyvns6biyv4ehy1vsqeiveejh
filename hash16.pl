# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$

# Display 16-bit hash of a string using a simple GUI.


use strict;
use Tk;
use FindBin;
use lib "$FindBin::Bin";
use Lib::Adler16_DFBD2442_9589_11D6_9520_009027319575;


my($w, $f, $s, $dec, $hex, @p);
@p= qw/-side left/;
$w= MainWindow->new(-title => 'ADLER-16 Checksummer');
$f= $w->Frame->pack;
$f->Label(-text => 'String:')->pack(@p);
$f->Entry(
   -textvariable => \$s, qw/-width 40 -validate all/
   , -validatecommand => sub {
      my $s= shift;
      $dec= Lib::Adler16::sum(defined $s ? $s : '');
      $hex= sprintf '%#06x', $dec;
      return 1;
   }
)->pack(@p);
$f= $w->Frame->pack(qw/-pady 1m/);
$f->Label(-text => 'Checksum is ')->pack(@p);
$f->Entry(-textvariable => \$hex, -width => 7)->pack(@p);
$f->Label(-text => ' (hex), ')->pack(@p);
$f->Entry(-textvariable => \$dec, -width => 6)->pack(@p);
$f->Label(-text => ' (dec)')->pack(@p);
$w->Button(
   -text => 'Exit', -command => [$w => 'destroy']
)->pack;
MainLoop;
