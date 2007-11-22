# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


# Sort sections and values in INI-like files


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::SimpleParser_8AEE1C20_CBA0_11D5_9920_C23CC971FBD2;


package TempFile;


use Carp;


sub new {
 my($class)= shift;
 my $self= {};
 bless $self, ref $class || $class;
 $self->{cnt}= 0;
 $self;
}


sub DESTROY {
 my($self)= @_;
 eval {$self->remove};
 carp $@ if $@;
}


sub remove {
 my($self)= @_;
 if (defined $self->{fh}) {
  my $success= close $self->{fh};
  undef $self->{fh};
  croak "Cannot close temporary file '$self->{filename}'!" unless $success;
  unlink $self->{filename}
  or croak "Cannot remove temporary file '$self->{filename}'!"
  ;
 }
}


sub create {
 my($self)= @_;
 my($td, $tf);
 local(*TMP);
 foreach (
  $ENV{TEMP},
  $ENV{TMP},
  "$ENV{WINDIR}\\TEMP",
  "$ENV{SystemDrive}\\TEMP",
  map(("$_:\\TEMP", "$_:"), 'C' .. 'Z'),
 ) {
  next unless $_ gt '';
  $td= $_;
  $td =~ s!(.*)[\\/]*$!$1\\!;
  if (-d "$td.") {
   do {
    $tf= $td . '~' . $$ . '~' . $self->{cnt} . '.tmp';
    ++$self->{cnt};
   }
   while -e $tf;
   if (open TMP, '+>', $tf) {
    $self->{filename}= $tf;
    return $self->{fh}= *TMP{FILEHANDLE};
   }
  }
 }
 croak "Cannot determine temporary directory!";
}


sub copyback {
}


package main;


die <<"---" unless @ARGV == 2;
Usage: $0 <input.ini> <output.ini>
---
my($temp, $t);

$temp= new TempFile;
$t= $temp->create;
print $t "this is so\n";
print $t "this is this\n";
seek $t, 0, 0;
$t= <$t>;
print "fn '$t'\n";
#open IN, '<', $ARGV[0] or die "Cannot create input file '$ARGV[0]'!";
#open OUT, '>', $ARGV[1] or die "Cannot create output file '$ARGV[1]'!";
#Process($ARGV[0], *IN{FILEHANDLE}, *OUT{FILEHANDLE});
#close OUT or die;
#close IN or die;




sub Process {
 my($in_name, $in, $out)= @_;
 my($p, %sects);
 $p= new Lib::SimpleParser;
 $p->init(-filename => $in_name, -fh => $in);
 ReadSections(\%sects, $p);
 $p->close;
 WriteSections($out, \%sects);
}


sub TryParseSectionHeader {
 my($p)= @_;
 my($name);
 $p->skip_ws_eol;
 return undef unless defined $p->try_parse_string('[');
 $p->parse_until(
  -result => \$name, -min_size => 1,
  -delimiters => ["\n" => undef, ']' => 0, '[' => undef]
 );
 $name =~ s/^\s*(.*?)\s*$/$1/;
 if ($name eq '') {
  $p->raise_error('invalid section name');
 }
 $p->skip_ws;
 $p->parse_eol;
 $name;
}


# Returns number of letter case changes in a string.
sub CaseChanges {
 my($str)= @_;
 my($i, $cc, $lc, $ncc, $c);
 $lc= $ncc= 0;
 for ($i= length($str); $i--; ) {
  $c= substr $str, $i, 1;
  if ($c =~ /[:lower:]/) {
   $cc= 1;
  }
  elsif ($c =~ /[:upper:]/) {
   $cc= 2;
  }
  else {
   $cc= 0;
  }
  if ($cc != $lc) {
   ++$ncc;
   $lc= $cc;
  }
 }
 $ncc;
}


sub IsBetterName {
 my($test, $than)= @_;
 CaseChanges($test) > CaseChanges($than);
}


sub TryParseValue {
 my($p, $refcontents)= @_;
 my($c, $name);
 $p->skip_ws_eol;
 if (!defined($c= $p->try_get_char) || $c eq '[') {
  $p->unget_char($c);
  return undef;
 }
 $p->unget_char($c);
 $p->parse_until(
  -delimiters => ['=' => 0, "\n" => undef],
  -result => \$name, -min_size => 1
 );
 $name =~ s/^\s*(.*?)\s*$/$1/;
 if ($name eq '') {
  die 'Missing value name in line ' . $p->get_line . '!';
 }
 $p->parse_until(-delimiters => ['' => 0, "\n" => 0], -result => \$c);
 $c =~ s/^\s*(.*?)\s*$/$1/;
 $$refcontents= $c;
 $name;
}


sub TryReadValue {
 my($values, $p)= @_;
 my($vn, $v, $vc);
 return undef unless defined ($vn= TryParseValue($p, \$vc));
 $v= uc($vn);
 unless (exists $values->{$v}) {
  $values->{$v}= {};
  $values->{$v}->{name}= $vn;
  $values->{$v}->{contents}= $vc;
 }
 else {
  $values->{$v}->{name}= $vn if IsBetterName($vn, $values->{$v}->{name});
  if ($values->{$v}->{contents} ne $vc) {
   print STDERR
   "Warning: value '$vc' overwrites '$values->{$v}->{contents}'!\n"
   ;
   $values->{$v}->{contents}= $vc;
  }
 }
 1;
}


sub TryReadSection {
 my($scs, $p)= @_;
 my($sn, $s);
 # Get header.
 return undef unless defined ($sn= TryParseSectionHeader($p));
 $s= uc($sn);
 unless (exists $scs->{$s}) {
  $scs->{$s}= {};
  $scs->{$s}->{name}= $sn;
  $scs->{$s}->{values}= {};
 }
 else {
  $scs->{$s}->{name}= $sn if IsBetterName($sn, $scs->{$s}->{name});
 }
 $s= $scs->{$s};
 # Get values.
 while (TryReadValue($s->{values}, $p)) {}
 1;
}


sub ReadSections {
 while (TryReadSection(@_)) { }
}


sub WriteValues {
 my($fh, $vals)= @_;
 foreach (sort {$vals->{$a}->{name} cmp $vals->{$b}->{name}} keys %$vals) {
  print $fh "$vals->{$_}->{name}=$vals->{$_}->{contents}\n";
 }
}


sub WriteSections {
 my($fh, $scs)= @_;
 foreach (sort {$scs->{$a}->{name} cmp $scs->{$b}->{name}} keys %$scs) {
  print $fh "[$scs->{$_}->{name}]\n";
  WriteValues($fh, $scs->{$_}->{values});
  print $fh "\n";
 }
}
