# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/charfreqs.pl 2647 2006-08-26T07:45:40.216781Z gb  $
# Determine octet / character frequencies.
open IN, '<', $ARGV[0] or die;
binmode IN or die;
for (;;) {
 die $! unless defined read IN, $buf, 0x8000;
 for ($i= length($buf); $i--; ) {
  $c= unpack '@' . $i . 'C', $buf;
  ++$h{$c};
 }
 last if eof IN;
}
close IN or die;
@f= map {[$_, $h{$_}]} keys %h;
@f= sort {$b->[1] <=> $a->[1]} @f;
for ($i= 0; $i < @f; ++$i) {
 my $n= $f[$i]->[0];
 if (chr($n) =~ /[[:graph:]]/) {
  $n= "'" . chr($n) . "'";
 }
 else {
  $n= sprintf "0x%02x", $n;
 }
 print "$n\t$f[$i]->[1]\n";
}
