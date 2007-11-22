# Compresses or expands local paths using environment variables.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/pathexpand.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use Tk;
use Tk::Font;
use Tk::LabFrame;
use strict;


sub settext {
 my($widget, $data)= @_;
 $data= '' unless defined $data;
 while (chomp($data)) {}
 $widget->delete('1.0', 'end');
 $widget->insert('end', $data . "\n");
}


my($wnd, $ow, $f, @p1);
$wnd= MainWindow->new(-title => 'EnvVar Substitution');
$wnd->Label(
 -text => 'Environment Variable Expander/Compressor'
 , -font => $wnd->Font(-size => 16))->pack;
$f= $wnd->Frame->pack(qw/-fill x -pady 5/);
@p1= qw/-side left -padx 5/;
$f->Label(-text => 'Text:')->pack(@p1);
$ow= $f->Scrolled(
 qw/Text -scrollbars e -width 77 -height 10 -wrap word/
)->pack(@p1);
$f= $wnd->Frame->pack(qw/-fill x -pady 5/);
$f->Button(
 qw/-text Compress/
 , -command => sub {
 }
)->pack(@p1, qw/-side left -padx 5/);
$f->Button(
 qw/-text Expand/
 , -command => sub {
  $t= $ow->get(qw/1.0 end/);
 }
)->pack(@p1, qw/-side left -padx 5/);
$f->Button(qw/-text Quit/, -command => [$wnd => 'destroy'])->pack(
 @p1, qw/-side right -padx 5/
);
$f= $wnd->Menu(qw/-type menubar/);
$wnd->configure(-menu => $f);
{
 my $m;
 $m= $f->cascade(-label => 'File', -tearoff => 0);
 $m->command(-label => 'Exit', -command => [$wnd => 'destroy']);
}
MainLoop;
