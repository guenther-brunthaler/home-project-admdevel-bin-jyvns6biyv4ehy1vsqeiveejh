# Calculates Ackermann's function.
#
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/ackermann.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


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
