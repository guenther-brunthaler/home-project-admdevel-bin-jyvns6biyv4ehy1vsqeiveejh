# Classifies file name extensions by contents.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/classify_extensions.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $

# Binary files larger than this number of bytes will be ignored upon import
# rather than be imported as binary files.
my $binary_rejection_threshold= 3072;

# Must be low enough to avoid runtime error
# "Complex regular subexpression recursion limit ... exceeded"
my $buf_size= 0x7000;


# 09, 0c allowed
# 20-7e, a0-ff allowed
# 0d0a allowed
# 0d allowed at end
# 0a allowed at begin if last ended at 0d
# 1a can be last only
sub is_text {
 my($fh)= @_;
 my($b, $lc, $r);
 my $p= 0;
 for ($lc= 'A';;) {
  $r= read($fh, $b, $buf_size);
  die unless defined $r;
  last if $r == 0;
  if (
   $b !~ /
    ^(?:[\x09\x0c\x20-\x7e\xa0-\xff] | \x0d\x0a | \x0d$ | \x1a$ | ^\x0a)+$
   /x
   || substr($b, 0, 1) eq "\x0a" && $lc ne "\x0d"
  ) {
   if (0) {
    if (substr($b, 0, 1) eq "\x0a" && $lc ne "\x0d") {
     print "0a w/o 0d\n";
    }
    else {
     $b =~ /
      ^((?:[\x09\x0c\x20-\x7e\xa0-\xff] | \x0d\x0a | \x0d$ | \x1a$ | ^\x0a)+)
     /x;
     printf "binary @ %0x\n", $p + length($1);
    }
   }
   return 0;
  }
  $p+= $r;
  if (substr($b, -1) eq "\x1a") {
   $r= read($fh, $b, $buf_size);
   die unless defined $r;
   last if $r == 0;
   return 0;
  }
  $lc= substr $b, -1; 
 }
 1;
}


while (<>) {
 chomp;
 if (open IN, '<', $_) {
  binmode IN or die;
  if (is_text(*IN{FILEHANDLE})) {
   $c= 'T';
  }
  elsif (-s $_ <= $binary_rejection_threshold) {
   $c= 'B';
  }
  else {
   $c= 'R';
  }
  close IN or die;
  print "$c\t$_\n";
 }
}
