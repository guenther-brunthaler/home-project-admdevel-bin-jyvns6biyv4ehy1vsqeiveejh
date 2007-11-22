# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;
my $analyze_max= 1000;
my $emulate= 0;


my(@lines, $i, $st, $fn, $fnb, $prefix, $postfix, $pat);


while ($fn= <>) {
 chomp $fn;
 next if $fn =~ /\.bak$/;
 next unless -w $fn;
 next unless open ORIG, '<', $fn;
 splice @lines; undef $st;
 for ($i= $analyze_max; --$i >= 0; ) {
  last unless defined($_= <ORIG>);
  if (
   /
    \$xsa
    (?:\s*\d{1,5}\s*=)?
    \s*{(?i:FBF02760-95CF-11D3-BD96-0040C72500FD)}\s*
    \$
   /x
  ) {
   undef $st; last;
  }
  $st= @lines if !defined $st && /
   \$
   (?:Revision|Date|Author)
   :\s*
   (?:
    \d{1,5}
    (?:\.\d{1,5})*
   )?\s*
   \$
  /x;
  push @lines, $_;
 }
 if (defined $st) {
  die unless $lines[$st] =~ /
   ^(.*?)
   \$
   (?:Revision|Date|Author)
   :\s*
   (?:
    \d{1,5}
    (?:\.\d{1,5})*
   )?\s*
   \$
   (?:\s*\([^)]+\))?
   (.*?)\s*$
  /x;
  ($prefix, $postfix)= ($1, $2);
  {
   my($pre, $post)= map(quotemeta, $prefix, $postfix);
   $pat= qr/^$pre\$[^\$]*\$(\s*\([^)]+\))?$post\s*$/;
  }
  $fnb= $fn . '.bak';
  open BAK, '+>', $fnb or die;
  print BAK @lines;
  {
   my $cont= tell BAK;
   print BAK while defined($_= <ORIG>);
   seek BAK, $cont, 0;
  }
  splice @lines, $st, 1 while $lines[$st] =~ $pat;
  splice @lines, --$st, 1 while $st > 0 && $lines[$st - 1] =~ $pat;
  $prefix.= '$xsa1$' . $postfix . "\n";
