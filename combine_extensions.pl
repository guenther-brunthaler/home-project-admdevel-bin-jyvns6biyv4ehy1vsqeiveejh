# Classifies file name extensions by contents.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/combine_extensions.pl 2647 2006-08-26T07:45:40.216781Z gb  $

@force_ignore= (
 qw/log rpt gon cmp err com res plg ncb opt $rc map lst/,
 qw/aps/
);
@force_text= (
 qw/c cc cpp cxx h hh hpp hxx inl/,
 qw/asm inc masm/,
 qw/bas vbs js java html htm xml dtd sgml/,
 qw/pl pm awk idl odl y l/,
 qw/bat cmd mak mk dsp dsw/,
 qw/txt rtf rc hpj def dlg/,
 qw/rul bnf/,
 qw/app/
);
@force_binary= (
 qw/ico/,
);

%cls= ('T' => 1, 'B' => 2, 'R' => 3);
while (<>) {
 die unless /^([TBR])\s+(.+?)\s*$/;
 ($mode, $fn)= ($1, $2);
 next unless $fn =~ /\.([^\/\\:]+)$/;
 $x= lc $1;
 if (
  !exists($x{$x})
  || $x{$x} ne $mode
  && $cls{$mode} > $cls{$x{$x}}
 ) {
  $x{$x}= $mode;
 }
}
@overrides= (map([$_, 'T'], @force_text), map([$_, 'R'], @force_ignore));
foreach $x (keys %x) {
 next unless exists $x{$x};
 foreach (@overrides) {
  ($frx, $fm)= @$_;
  $fx= '.' . lc($frx);
  if (
   $x eq lc($frx)
   || length($x) >= length($fx) && lc(substr($x, -length($fx))) eq $fx
  ) {
   delete $x{$x};
   $x{$frx}= $fm;
  }
 }
}
foreach (@overrides) {
 ($frx, $fm)= @$_;
 $x{$frx}= $fm;
}
foreach (sort grep {$x{$_} eq 'T'} keys %x) {
 print "*.$_ -k 'o'\n";
}
print "*.* -k 'b'\n\n";
foreach (sort grep {$x{$_} eq 'R'} keys %x) {
 print "*.$_\n";
}
