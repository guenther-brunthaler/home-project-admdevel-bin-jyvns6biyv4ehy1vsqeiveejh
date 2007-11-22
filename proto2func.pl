# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=C++ ProtoGen$
# C++ prototype function generator.
# $xsa2:description$
# This tool shows a window in which one can paste C++ class declarations
# or declarations for normal functions.
#
# When the button is pressed, any C or C++ remarks are stripped, symbol
# namespace is determined and C++ functions are created from the
# declarations with an function body that just throws a
# "not yet implemented" error.
#
# The tool is not perfect and the output needs manual correction in
# most cases, but it can save a considerable amount of time in cases
# when implementing a class with many member functions.
# $xsa2:end$


use Tk;
use Tk::Font;
use strict;


sub cleanup {
 my($text)= @_;
 # Remove C++ remarks.
 $text =~ s!//[^\n]*!!gs;
 # Remove C remarks.
 $text =~ s!/\*.*?\*/!!gs;
 # Compress spaces, convert tabs to spaces.
 $text =~ s/[\t \xa0]+/ /gs;
 while ($text =~ s/\n +| +\n/\n/gs) {}
 $text =~ s/^ *| *$//gs;
 # Remove unnecessary spaces.
 while ($text =~ s/(?<=[([])\ +| +(?=[()[\]])//gs) {}
 # Line compression: empty/leading/trailing line removal.
 $text =~ s/\n{2,}/\n/gs;
 $text =~ s/^\n*(.*?)\n*$/$1/gs;
 $text;
}


sub process {
 my($text)= @_;
 my(@t, @ns);
 $text= cleanup $text;
 # Remove leading "virtual".
 while ($text =~ s/\bvirtual\b//gs) {};
 # Remove protection modifiers.
 while ($text =~ s/\b(?:private|public|protected)\s*://gs) {};
 # Remove inheritance specifications.
 while ($text =~ s/(?<!:):(?!:)\s*(?:[^\s{]|:{2,})*\s*(?={)//gs) {};
 #open OUT, ">log";
 @t= split /;/, $text;
 foreach my $nss (@t) {
  my(@nss)= split /(?<=[{}])/, $nss;
  foreach (@nss) {
   print OUT "\n\nBEFORE>>>>>$_<<<<<\n\n\n";
   if (s/ *(?:struct|namespace|union|class|enum) *(\S+) *{$//s) {
    push @ns, $1;
    #print OUT "\n\nNS>>>>>",join('::',@ns),"<<<<<\n\n\n";
   }
   elsif (s/ *}$//s) {
    pop @ns;
    #print OUT "\n\nNS>>>>>",join('::',@ns),"<<<<<\n\n\n";
   }
   if (/\) *(?:const)?$/s) {
    # Replace throw() specifications.
    s/throw *\(([^)]*)\)/{$1}/sg;
    my($i, $n, $c, $p);
    # Search for opening parenthesis of parameter list.
    $n= 0;
    for ($i= length; --$i >= 0; ) {
     if (($c= substr($_, $i, 1)) eq ')') {++$n}
     elsif ($c eq '(') {
      if (--$n == 0) {
       $p= substr($_, $i);
       $_= substr($_, 0, $i);
       last;
      }
     }
    }
    goto fail unless defined $p;
    goto fail unless s/ *((?:operator *)?[^ &*\n]+)$//s;
    $p= join('::', @ns, $1) . $p;
    while (s/\n| {2,}/ /sg) {};
    s/^ *| *$//sg;
    $_.= ' ' unless /^$|[\*&]$/;
    $_.= $p;
    s/{([^}]*)}/throw($1)/sg;
    $_.= '{' . $p . '}';
    #print OUT "\n\nHANDLED>>>>>$_<<<<<\n\n\n";
   }
   else {
    fail:
    $_= '';
   }
  }
  $nss= join('', @nss);
 } 
 $text= join('', @t);
 $text =~ s/\n/ /sg;
 $text= cleanup $text;
 $text =~ s/{([^}]+)}/ {\n throw std::runtime_error\(\n  "$1 "\n  "has not been implemented yet!"\n \);\n}\n\n\n/sg;
 #close OUT;
 $text;
}


my($wnd, $ow, $f, @p1);
$wnd= MainWindow->new(
 -title => 'C++ Prototype To Function Template Converter'
);
$wnd->Label(
 -text => 'C++ Function creator', -font => $wnd->Font(-size => 16)
)->pack;
$f= $wnd->Frame->pack(qw/-fill x -pady 5/);
@p1= qw/-side left -padx 5/;
$ow= $f->Scrolled(
 qw/Text -scrollbars se -width 77 -height 20 -wrap none/
)->pack(@p1);
$f= $wnd->Frame->pack(qw/-fill x -pady 5/);
$f->Button(
 -text => 'Convert', -command => sub {
  my($data);
  $data= process($ow->get(qw/ 1.0 end/));
  while (chomp($data)) {}
  $ow->delete('1.0', 'end');
  $ow->insert('end', $data . "\n");
 }
)->pack(@p1);
$f->Button(qw/-text Quit/, -command => [$wnd => 'destroy'])->pack(
 @p1, qw/-side right -padx 5/
);
MainLoop;
