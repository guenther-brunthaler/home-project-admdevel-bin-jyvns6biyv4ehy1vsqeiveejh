# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;
use FindBin;
use lib "$FindBin::Bin";
use File::Spec;
use Carp;
use Tk;
use Tk::Font;
use Tk::Balloon;
use Lib::XSA_8AEE1C25_CBA0_11D5_9920_C23CC971FBD2;


my($main, $f, @px, @py, $stringdata, $i);
my(@plist, $lbx, $title, $launch, $description);
$main= new MainWindow(-title => 'PERL Tools'); 
eval {
 @plist= &GetProgramList;
 # Create main dialog
 @py= qw/-side top/;
 $main->Label(
  -text => 'PERL Application Launcher',
  -font => $main->Font(-size => 16)
 )->pack(@py);
 $lbx= $main->Scrolled(qw/Listbox -scrollbars e -setgrid 1/);
 $lbx->pack(@py, qw/-fill both -expand 1/);
 for ($i= 0; $i < @plist; ++$i) {
  $lbx->insert($i, $plist[$i]->{title});
 }
 $f= $main->Frame->pack(@py);
 $title= $f->Label;
 $title->pack qw(-side left);
 $launch= $f->Button(
  -text => 'Please select a list entry from the list',
  -command => \&LaunchEntry
 );
 $launch->pack qw(-side left);
 $description= $main->Label(qw/-justify left -wraplength 4i/);
 $description->pack qw(-fill x);
 $main->Button(-text => 'Quit', -command => [$main => 'destroy'])->pack;
 $lbx->bind('<Button-1>' => \&SelectEntry);
 # run main dialog message loop
 MainLoop;
}
&DisplayAnyError($main);
exit;


sub SelectEntry {
 my($lbx)= @_;
 my($e, $cmd);
 return unless defined($e= $lbx->curselection);
 $e= $plist[$e];
 $title->configure(-text => $e->{title});
 $launch->configure(-text => "Run '" . $e->{caption} . "'");
 $description->configure(-text => $e->{description});
}


sub LaunchEntry {
 my($e, $cmd);
 return unless defined($e= $lbx->curselection);
 $e= $plist[$e];
 $cmd= 'perl "' . $e->{filename} . '"';
 if ($^O =~ /Win32/) {
  $cmd= 'start ' . $cmd;
 }
 else {
  $cmd.= '&';
 }
 if (system $cmd) {
  my $failure= $? >> 8;
  die "Command '" . $e->{filename} . "' failed (returncode $failure)";
 }
}


# Returns a list of hashes, one entry per tool program.
sub GetProgramList {
 my(@plist, $fd, $p, $fn);
 $p= File::Spec->catfile($FindBin::Bin, '*.pl');
 $p =~ s/\\/\//g;
 $p =~ s/(\s)/\\$1/g;
 while ($fn= glob $p and -r $fn) {
  if ($fd= FetchDetails($fn)) {
   $fd->{filename}= $fn;
   push @plist, $fd;
  }
 }
 sort {$::a->{title} cmp $::b->{title}} @plist;
}


sub DisplayAnyError {
 my($wnd)= @_;
 return unless $@;
 $main->messageBox(
  qw/-icon error -title Error/,
  -message => $@
 );
}


# Extracts the text from remark lines stored in the specified
# variable and returns it.
# Leading and trailing whitespace will be removed from the individual
# remark lines, and they will also be merged to a single line unless
# they are separated by an empty remark line, which will converted
# to a single newline character.
# The variable, a which must have been specified as a reference,
# will be cleared.
sub ExtractCommentText {
 my($buf_)= @_;
 my($buf);
 $buf= $$buf_;
 $$buf_= '';
 $buf =~ s/^\s*#\s*(.*)$/$1/s;
 $buf =~ s/^(.*?)\s*#\s*$/$1/s;
 $buf =~ s/[\t ]*\n#[\t ]*/\n/sg;
 $buf =~ s/(?<!\n)\n(?!\n)/ /sg;
 $buf;
}


# Examines whether a PERL script is a GUI application following
# the XSA C<{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}> specification.
# If not, returns C<undef>.
# If yes, then the reference to an anonymous hash containing information
# on the PERL script is returned.
sub FetchDetails {
 my($filename)= @_;
 local(*IN);
 my($xsa, $result, $state, $buf);
 $xsa= new Lib::XSA;
 open IN, '<', $filename or croak qq<cannot open file "$filename" for reading>;
 $xsa->set(
  -in => *IN{FILEHANDLE},
  -filter => [
   '{8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}',
   'title=',
   'description',
   'end'
  ]
 );
 $state= 0;
 while ($xsa->read) {
  if ($xsa->is_mark) {
   if ($xsa->filtered_mark) {
    if ($state == 0) {
     $xsa->require_command('title');
     $result= {};
     $result->{caption}= $xsa->get_cmd_arg;
     ++$state;
    }
    elsif ($state == 1) {
     $xsa->require_command('description');
     $result->{title}= ExtractCommentText(\$buf);
     ++$state;
    }
    else {
     $xsa->require_command('end');
     $result->{description}= ExtractCommentText(\$buf);
     last;
    }
   }
  }
  elsif ($state > 0) {
   $buf.= $xsa->get_text;
  }
 }
 close IN or die;
 $result;
}
