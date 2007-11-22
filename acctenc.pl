# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=Account-Encoder$
# Account-Information Encoder.
# $xsa2:description$
# This tool encodes the user name and password into a single string
# that is used to provide user name and passwords to several Perl tools.
#
# It is typically used for providing database or login-account information.
# $xsa2:end$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Tk;
use Tk::Font;
use Lib::AcctEncode_0EEED082_DA7D_11D5_98D3_0050BACC8FE1;


my($wnd, $ow, $f, @p1, $ok);
$wnd= MainWindow->new(-title => 'Account Encoder');
$wnd->Label(
 -text => 'Account Information Encoder', -font => $wnd->Font(-size => 16)
)->pack;
$f= $wnd->Frame->pack(qw/-fill both -expand y/);
my($sw, $help, $f2, $r, %opt);
$r= 0;
foreach (
 ['user', 'User Name'],
 ['password', 'Password'],
 ['acct_info', 'Encoded Information']
) {
 my $t= $_->[1] . ':';
 $f->Label(
  -text => $_->[1] . ':'
 )->grid(-row => ++$r, qw/-sticky e/);
 $f->Entry(
  -textvariable => \$opt{$_->[0]}, qw/-width 30/
 )->grid(-row => $r, qw/-column 1/);
}
foreach (
 [
  'Encode',
  sub {
   $opt{acct_info}= Lib::AcctEncode map {
    /\S/ ? $opt{$_} : undef
   } 'user', 'password';
  }
 ],
 ['Quit', [$wnd => 'destroy']]
) {
 $wnd->Button(
  -text => $_->[0], -command => $_->[1]
 )->pack(qw/-side right -padx 5 -pady 5/);
}
MainLoop;
