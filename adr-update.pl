# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$

# Creates "W:\adr" from "W:\email-update.txt"


use strict;


sub EmailifyName {
 my($name)= @_;
 if (defined($name)) {
  my($pat);
  foreach (
   [qw/Ä ä Æ æ ae/],
   [qw/Ö ö oe/],
   [qw/Ü ü ue/],
   [qw/ß ss/],
   [qw/Œ œ ce/],
   [qw/Š š s/],
   [qw/Ç ç c/],
   [qw/À Á Â Ã Å à á â ã å a/],
   [qw/È É Ê Ë è é ê ë e/],
   [qw/Ì Í Î Ï ì í î ï i/],
   [qw/Ð ð d/],
   [qw/Ñ ñ n/],
   [qw/Ò Ó Ô Õ ò ó ô õ Ø ø o/],
   [qw/Ù Ú Û ù ú û u/],
   [qw/Ý ý ÿ y/],
   [qw/Þ þ p/]
  ) {
   # Build regular expression match pattern.
   $pat= join('|', map(quotemeta, @$_[0 .. @$_ - 2]));
   $name =~ s/$pat/$_->[@$_ - 1]/g;
  }
  # Remove all non-e-mail characters.
  $name =~ s/[^-_.a-zA-Z@ 0-9]//g;
 }
 $name;
}


sub mksentence {
 my($s)= @_;
 $s.= '.' unless $s =~ /[.!?]$/;
 $s;
}


my(@g, @e, $i, @he, @h, %f, %a, @rl, %o, @oo, %n);
my($dtremark, @sp, $st);
my($st_initial, $st_new_group, $st_read_more, $st_terminate, $st_write_group, $st_write_last)= (1 .. 6);
# Field order for output.
@oo= qw(Name Addresses Comments Field-Text);
# Fields to be used for grouping entry blocks.
@g= qw/Titel Name Rubrik/;
$dtremark= "\nWARNING:\n"
. "Do not try to edit this entry, because it will be\n"
. "overwritten by the next address book update.\n\n"
. "This entry has been automatically generated\n"
. "on " . scalar(localtime time) . " by $0 based on\n"
. "data extracted from the EVIS address database."
;
open IN, '<', 'W:\\email-update.txt' or die;
open OUT, '>', 'W:\\adr' or die;
foreach (@oo) {
 $o{$_}= '';
}
# Get header
die unless defined($_= <IN>);
chomp;
@h= map {
 $_= EmailifyName($_);
 s/[^0-9a-z_]//ig;
 $_;
} split /\t/;
# Process adresses.
for ($st= $st_initial;;) {
 die unless $st == $st_initial || $st == $st_new_group;
 do {
  unless ($st == $st_new_group) {
   # Try to read next record.
   $st= $st_new_group if $st == $st_initial;
   unless (defined($_= <IN>)) {
    $st= $st == $st_new_group ? $st_terminate : $st_write_last;
   }
   if ($st == $st_new_group || $st == $st_read_more) {
    # Read fields.
    chomp;
    @rl= split /\t/;
    $#rl= $#h;
    for ($i= 0; $i < @rl; ++$i) {
     $f{$h[$i]}= $rl[$i];
    }
   }
  }
  if ($st == $st_new_group) {
   # Start new entry block.
   foreach (@g) {
    $a{$_}= $f{$_};
   }
   splice @e;
  }
  die unless $st == $st_read_more || $st == $st_new_group
  || $st == $st_terminate || $st == $st_write_group || $st == $st_write_last
  ;
  if ($st == $st_read_more) {
   foreach (@g) {
    if ($a{$_} ne $f{$_}) {
     $st= $st_write_group;
     last;
    }
   }
  }
  elsif ($st == $st_new_group) {
   $st= $st_read_more;
  }
  die unless $st == $st_read_more || $st == $st_terminate
  || $st == $st_write_group || $st == $st_write_last
  ;
  if ($st == $st_read_more) {
   push @e, {};
   foreach (@h) {
    # Collect all fields except for grouping fields.
    $e[$#e]->{$_}= $f{$_} unless exists $a{$_};
   };
  }
 } while ($st == $st_read_more);
 last if $st == $st_terminate;
 die unless $st == $st_write_group || $st == $st_write_last;
 # Split @e into @e for normal entries and @he for header entries.
 splice @he;
 for ($i= 0; $i < @e; ) {
  if ($e[$i]->{Attribut} =~ /e.*mail/i) {
   push @he, splice(@e, $i, 1);
   next;
  }
  ++$i;
 }
 die unless $a{Name} =~ /^(.+?)\s+([^ ]+)$/;
 ($a{FirstName}, $a{LastName})= ($1, $2);
 unless (@he) {
  $o{Name}= "$a{LastName}, $a{FirstName} ($a{Rubrik})";
  foreach (@e) {
   print "Ignoring '$_->{Attribut}' for '$o{Name}':\n";
   print " Category '$a{Rubrik}' has no associated e-email-address!\n";
  }
 }
 foreach (@he) {
  $o{Addresses}= $a{Titel} gt '' ? $a{Titel} . ' ' : '';
  $o{Addresses}= EmailifyName($o{Addresses} . $a{Name});
  $o{Addresses}.= ' <' . $_->{Wert} . '>';
  $o{Name}= "$a{LastName}, $a{FirstName} ($a{Rubrik})";
  while (exists $n{$o{Name}}) {
   die unless $o{Name} =~ /^(.+?)(\d*)(\))$/;
   $o{Name}= $1 . ($2 ? $2 + 1 : ' 2') . $3;
  }
  undef $n{$o{Name}};
  $o{Comments}= '$xsa{D491B380-5112-11D5-9841-0050BACC8FE1}$';
  $o{Comments}.= "\nAnmerkung: " . mksentence($_->{Anmerkung}) if $_->{Anmerkung} gt '';
  foreach (@e) {
   if ($_->{Wert} gt '') {
    $o{Comments}.= "\n$_->{Attribut}: " . $_->{Wert};
    $o{Comments}.= ' (' . $_->{Anmerkung} . ')' if $_->{Anmerkung} gt '';
    $o{Comments}= mksentence $o{Comments};
   }
  }
  $o{Comments}.= "\n" if @e;
  $o{Comments}.= $dtremark;
  foreach my $h (@oo) {
   print OUT $h, ':';
   @sp= split "\n", $o{$h};
   @sp= ('') if @sp == 0;
   foreach (@sp) {
    print OUT " $_\n";
   }
  }
  print OUT "\n";
 }
 last if $st == $st_write_last;
 $st= $st_new_group;
}
close OUT or die;
close IN or die;
