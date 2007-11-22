# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$

# Calculate optimum anamorpic width resizing for DivX.


use strict;
use Tk;


my($w, $f, $in_width, $out_width, @p);
@p= qw/-side left/;
$w= MainWindow->new(-title => 'DivX Anamorphic Calculator');
$f= $w->Frame->pack;
$f->Label(-text => 'DVD source pixel width:')->pack(@p);
$f->Entry(
   -textvariable => \$in_width, qw/-width 5 -validate all/
   , -validatecommand => sub {
      my $w= shift;
      if (!defined($w) || $w !~ /\d+/) {
         undef $out_width;
         return 1;
      }
      $w= $w * 1024 / 720;
      my $lb= int $w;
      my $ub= 4 + ($lb-= $lb % 4);
      $out_width= $w - $lb <= $ub - $w ? $lb : $ub;
      return 1;
   }
)->pack(@p);
$f= $w->Frame->pack(qw/-pady 1m/);
$f->Label(-text => 'Resize width to ')->pack(@p);
$f->Entry(-textvariable => \$out_width, -width => 5)->pack(@p);
$f->Label(-text => 'pixels')->pack(@p);
$w->Button(
   -text => 'Exit', -command => [$w => 'destroy']
)->pack;
MainLoop;
