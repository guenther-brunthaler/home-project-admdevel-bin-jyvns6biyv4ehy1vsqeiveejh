#! /usr/bin/perl
# Calculates Ackermann's function.
#
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/ackermann.pl 2647 2006-08-26T07:45:40.216781Z gb  $


sub Ackermann($$) {
   my($m, $n)= @_;
   # A(0, n) = n + 1
   return $n + 1 if $m == 0;
   # A(m, 0) = A(m-1, 1)
   return Ackermann($m - 1, 1) if $n == 0;
   # A(m, n) = A(m-1, A(m, n-1))
   return Ackermann($m - 1, Ackermann($m, $n - 1));
}


my($m, $n)= splice @ARGV, 0, 2;
die "Usage: $0 <m> <n>" if @ARGV;
print "Ackermann($m, $n):= ", Ackermann($m, $n), "\n";
