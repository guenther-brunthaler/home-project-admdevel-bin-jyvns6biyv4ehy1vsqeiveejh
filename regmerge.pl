# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$

# Registry Script Merger


use strict;
use Getopt::Long;


my $Usage= <<"_E_N_D_";
$0 [-o outputfile ] [-r] [(file | pattern) ...]
$0 -h | --help

RegMerge merges several registry script files (*.reg) into a single file
and removes any duplicate or unnecessary entries.

It also sorts the registry keys and values before output.

Unless the -o option is specified, output is written to the standard output
stream.

If the -r option is present, the files and patterns are searched
recursively starting in the current directory.

Any number of files or file patterns (containing * and ? wildcards) can
be specified.

If no files or patterns are specified, the file names are read from
the standard input stream.

$0 has been written in 2000
by Guenther Brunthaler
_E_N_D_


my($opt_help, $opt_output, $opt_recursive, $pattern);
Getopt::Long::Configure("bundling");
GetOptions(
 'h|help' => \$opt_help,
 'o|output:s' => \$opt_output,
 'r|recursive' => \$opt_recursive
);
if (defined $opt_output) {
 open(STDOUT, '>', $opt_output) || die "Can't redirect standard output";
}
if ($opt_help) {
 print $Usage;
 exit;
}
if (@ARGV == 0) {
 push @ARGV, $_ while <STDIN>;
}
die "no files specified" if @ARGV == 0;
$pattern= join(' ', @ARGV);
my(%REG);
if ($opt_recursive) {
 &TraverseDir;
}
else {
 &Process while <${pattern}>;
}
&Optimize_Result;
&Report_Result;


sub TraverseDir {
 local *DIRECTORY;
 opendir DIRECTORY, '.' or return;
 while ($_= readdir(DIRECTORY)) {
  next if !-d $_ or /^\.(?:\.)?$/;
  if (chdir $_)  {
   &TraverseDir;
   chdir '..' or die;
  }
 }
 closedir DIRECTORY or die;
 &Process while <${pattern}>;
}


sub Process {
 my $file= $_;
 my(%env);
 open IN, '<', $_ or print STDERR "cannot open '$_'!\n" , return;
 if (<IN>=~ /^REGEDIT4\s*$/ && <IN>=~ /^\s*$/) {
  &HandleRegline(\%env) while <IN>;
 }
 else {
  print STDERR qq<Skipping non-registry file "$file"...\n>;
 }
 close IN or die;
}


sub HandleRegline {
 my($this)= @_;
 if (/^\s*\[(.+)\]\s*$/) {
  my $keyname= $1;
  my $key;
  if (exists $REG{$keyname}) {
   $key= $REG{$keyname};
  }
  else {
   $key= $REG{$keyname}= {};
  }
  $this->{KEYNAME}= $keyname;
  $this->{KEY}= $key;
 }
 elsif (/^\s*(.+)\s*$/) {
  my($value, $contents, $str, %p);
  &InitParser(\%p, $1);
  $value= (&GetToken(\%p, '='))[0];
  if (&GetChar(\%p) ne '=') {
   ignore:
   print STDERR qq<Ignoring line ">, &GetText(\%p), qq<"\n>;
  }
  ($contents, $str)= &GetToken(\%p);
  goto ignore if defined &GetChar(\%p);
  if (exists $this->{KEY}) {
   if (exists $this->{KEY}->{$value}) {
    if ($this->{KEY}->{$value}->[0] ne $contents) {
     print STDERR qq(Overwriting contents '$this->{KEY}->{$value}->[0]' with '$contents'\n);
     print STDERR qq( in value '$value' in key '$this->{KEYNAME}'!\n);
    }
   }
   else {
    $this->{KEY}->{$value}= [];
   }
   $this->{KEY}->{$value}->[0]= $contents;
   $this->{KEY}->{$value}->[1]= $str;
  }
  else {
   print STDERR qq<Ignoring assignment of value '$value' before first key!\n>;
  }
 }
}


sub InitParser {
 my($p, $string)= @_;
 $p->{BUF}= $string;
 $p->{POS}= 0;
}


sub GetToken {
 my($p, $term)= @_;
 my($quot, $esc, $c, $tok, $qlit, $hadq);
 $hadq= 0;
 while (defined($c= &GetChar($p))) {
  if ($esc) {
   $tok.= $c;
   $esc= 0;
  }  
  elsif ($c eq "\\") {
   $esc= 1;
  }
  elsif (($quot || !$qlit) && $c eq '"') {
   if ($quot) {
    $quot= 0;
    $qlit= 1;
   }
   else {
    $quot= 1;
    $hadq= 1;
   }
  }
  elsif (defined($term) && $c eq $term) {
   &UnGetChar($p);
   $term= undef;
   last;
  }
  else {
   next unless $quot || ($c!~ /\s/);
   $qlit= 1;
   $tok.= $c;
  }
 }
 if (defined $term) {
  missterm:
  print STDERR "Missing terminating '$term' in line '", &GetText($p), "'!\n";
  return;
 }
 if ($quot) {
  $term= '"';
  goto missterm;
 }
 if ($esc) {
  print STDERR "Missing escaped character in line '", &GetText($p), "'!\n";
  return;
 }
 ($tok , $hadq);
}


sub GetChar {
 my($p)= @_;
 my($p_, $b_)= (\$p->{POS}, \$p->{BUF});
 return undef if $$p_ >= length $$b_;
 substr $$b_, $$p_++, 1;
}


sub UnGetChar {
 my($p)= @_;
 --$p->{POS};
}


sub GetText {
 my($p)= @_;
 $p->{BUF};
}


sub Optimize_Result {
 my (@keys, $i, $lk, $lpk, $k);
 @keys= sort keys %REG;
 $lpk= 0;
 for ($i= 1; $i < @keys; ++$i) {
  $lk= length($k= $keys[$i]);
  if ($lk > $lpk && $keys[$i - 1] . "\\" eq substr($k, 0, $lpk + 1)) {
   if (%{$REG{$keys[$i - 1]}} eq '0') {
    delete $REG{$keys[$i - 1]};
   }
  }
  $lpk= $lk;
 }
}


sub Report_Result {
 my ($key, $value, $vals);
 print "REGEDIT4";
 foreach $key (sort keys %REG) {
  print "\n\n[$key]";
  $vals= $REG{$key};
  foreach $value (sort keys %$vals) {
   print "\n", &QuoteIfNecessary($value), '=';
   print &QuoteIfNecessary($vals->{$value}->[0], $vals->{$value}->[1]);
  }
 }
 print "\n\n";
}


sub QuoteIfNecessary {
 my($str, $override)= @_;
 return $str unless $override || &NeedsQuoting($str);
 &QuoteValue($str);
}


sub NeedsQuoting {
 my($str)= @_;
 return 1 if $str eq '';
 $str=~ /\s"\\/;
}


sub QuoteValue {
 my($str)= @_;
 $str=~ s/([\\"])/\\$1/g;
 '"' . $str . '"';
}
