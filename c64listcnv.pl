# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/c64listcnv.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# Converts C-64 BASIC listing files into PC text files.
$c= <<'END';
05 white
11 down
12 rvson
13 home
1c red
1d right
1e green
1f blue
81 orange
85 f1
86 f3
87 f5
88 f7
89 f2
8a f4
8b f6
8c f8
90 black
91 up
92 rvsoff
93 cls
94 insert
95 brown
96 lightred
97 darkgray
98 gray
99 lightgreen
9a lightblue
9b lightgray
9c purple
9d left
9e yellow
9f cyan
END
open IN, '<', $ARGV[0] or die "Cannot open: $!";
binmode IN or die;
for ($b= '';;) {
 $rd= read(IN, $bb, 0x2000);
 die unless defined $rd;
 last if $rd == 0;
 $b.= $bb;
}
close IN or die;
$b =~ s/\x0d/\x0d\x0a/gs;
foreach (split /\n/, $c) {
 next unless /^(..) (.+)$/;
 $c= '$b =~ s/\\x' . $1 . '/{' . $2 . '}/gs';
 eval $c;
}
open OUT, '>', $ARGV[0] . '.txt' or die "Cannot create: $!";
binmode OUT or die;
print OUT $b;
close OUT or die;
print "Done.\n";
