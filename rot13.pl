# Apply ROT-13 transformation to text.
# Written by Guenther Brunthaler.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/rot13.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# May be distributed under the GPL.


use Tk;


$w= MainWindow->new;
$tx= $w->Text(qw/-width 80 -height 10/)->pack;
$w->Button(
   qw/-text Rot-13 -command/, sub {
      $t= $tx->get(qw/1.0 end/);
      for ($i= 0; $i < length $t; ++$i) {
         $c= substr $t, $i, 1;
         if ($c ge "a" && $c le "z") {
            $c= chr((ord($c) - ord("a") + 13) % 26 + ord("a"));
         } elsif ($c ge "A" && $c le "Z") {
            $c= chr((ord($c) - ord("A") + 13) % 26 + ord("A"));
         }
         substr($t, $i, 1)= $c;
      }
      $t= '' unless defined $t;
      while (chomp($t)) {}
      $tx->delete('1.0', 'end');
      $tx->insert('end', $t . "\n");
   }
)->pack;
MainLoop;
