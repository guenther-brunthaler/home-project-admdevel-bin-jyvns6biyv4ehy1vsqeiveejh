# Convert between Azureus info hash and magnet link URL.
# Written by Guenther Brunthaler.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/magnetlinkcnv.pl 1020 2007-10-09T20:05:23.737461Z root  $
# May be distributed under the GPL.


use Tk;
use Math::BigInt;


sub encode($$$) {
   my($digits, $al, $int)= @_;
   my(@n);
   my $base= Math::BigInt->new(scalar @$al);
   while ($digits--) {
      push @n, $al->[$int->copy()->bmod($base)];
      $int->bdiv($base);
   }
   return join '', reverse @n;
}


sub decode($$) {
   my($al, $digits)= @_;
   my($i, %v);
   for ($i= @$al; $i--; ) {
      $v{$al->[$i]}= $i;
   }
   my $base= Math::BigInt->new(scalar @$al);
   my $n= Math::BigInt->new(0);
   for ($i= 0; $i < length $digits; ++$i) {
      $n->bmul($base);
      $n->badd($v{substr $digits, $i, 1});
   }
   return $n;
}


$w= MainWindow->new;
$tx= $w->Text(qw/-width 80 -height 10/)->pack;
$w->Button(
   qw/-text Convert -command/, sub {
      $t= $tx->get(qw/1.0 end/);
      if (
         $t =~ /
            (?: ^ | [^0-9a-f] )
            ( [0-9a-f]{40} )
            (?: [^0-9a-f] | $ )
         /x
      ) {
         $t= 'magnet:?xt=urn:btih:' . encode
            32, ['A' .. 'Z', '2' .. '7']
            , decode ['0' .. '9', 'a' .. 'f'], $1
         ;
      } elsif (
         $t =~ /
            (?: ^ | [^A-Z2-7] )
            ( [A-Z2-7]{32} )
            (?: [^A-Z2-7] | $ )
         /x
      ) {
         $t= 'Azureus info hash = ' . encode
            40, ['0' .. '9', 'a' .. 'f']
            , decode ['A' .. 'Z', '2' .. '7'], $1
         ;
      }
      $t= '' unless defined $t;
      while (chomp($t)) {}
      $tx->delete('1.0', 'end');
      $tx->insert('end', $t . "\n");
   }
)->pack;
MainLoop;
