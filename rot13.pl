#! /usr/bin/perl
# Apply ROT-13 transformation to text.
# Written by Guenther Brunthaler.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/rot13.pl 2647 2006-08-26T07:45:40.216781Z gb  $
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
