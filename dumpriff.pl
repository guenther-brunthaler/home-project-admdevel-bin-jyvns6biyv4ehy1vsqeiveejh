# Output the structure dump for a RIFF file.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/dumpriff.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Getopt::Long;
use Lib::RIFF_C19F8B63_C093_11D8_9140_00A0C9EF1631;


our $opt_linewidth= 79;
our $opt_dump;
our $opt_extract;
our $opt_blocksize= 0x2000;
our $opt_indent= 1;
our $opt_tabwidth= 8;
our $opt_url_encoding;
our $opt_replacement_char= '.';
our $opt_only_hex_dump;
our $opt_only_ascii_dump;
our $opt_items_per_line;
our $opt_multiples_per_line;
our $opt_power_of_2_multiples_only;
our $opt_hex_dump_prefix= '=';
our $opt_hex_dump_item_prefix= ' ';
our $opt_ellipsis= '...';
our $opt_hex_ascii_zone_separator= '  ';
our $opt_ascii_dump_begin_indicator= '"';
our $opt_ascii_dump_end_indicator= '"';


my $version= '$Revision: 2647 $ $Date: 2006-08-26T07:45:40.216781Z $';
$version =~ s/
 .+? Revision: \s+ ([^\$\s]+)
 .+ Date: \s+ ([^\$]+?)
 \s+ \$
/Version $1, $2/x
;
my $Usage= <<"END";
Usage: $0 (--help | -h)
Usage: $0 [options] <riff_file>
where
<riff_file> : RIFF file to be dumped.

Options:
--help, -h, -?: display this help
--line-width, -w: Maximum output line width. Defaults to $opt_linewidth.
--dump[=<max>], -d[max]: Dump up to <max> octets (or unlimited) of chunk data.
--extract[=<max>], -x[max]:
  Write up to <max> octets (or unlimited) of chunk data to a binary output
  file. Defaults to not extracting any chunk data to binary output files.
  If this option is enabled, the output files will have the same name as
  the input file, with a chunk identifier appended.
  This option is independent of --dump.
--block-size=<count>:
  Process I/O in chunks of <count> octets when extracting data (using the
  --extract option).
  A buffer of that size will be maintained internally.
  Defaults to $opt_blocksize.
--indent=<number>:
  Number of units to indent display for each deeper nested level.
  Defaults to $opt_indent.
--tab-width[=<width>]:
  Use tabs instead of spaces as the indentation character.
  If <width> is specified, a tab stop is assumed to be set all <width>
  output columns. (Defaults to $opt_tabwidth.)
--url-encoding:
  Non-printable character codes are simply displayed as '$opt_replacement_char'
  in the ASCII dump pane by default. When this option is used, they are
  displayed with the same "%"-hex-encoding as used in URLs.
--replacement-char="x":
  Changes the '$opt_replacement_char' character that is used as a replacement
  for non-printable characters in the ASCII dump pane to the specified
  character ("x" in this example).
--only-hex-dump: Display only the hex pane in chunk dumps.
--only-ascii-dump: Display only the ASCII pane in chunk dumps.
--items-per-line="<list>": By default, as many octets are dumped per
  line in chunk dumps as fit within the defined line width. With this option,
  "<list>" specifies a comma-separated list of possible item counts per line,
  and the best matching one will be selected.
  Example: items-per-line="8, 16, 32"
  will generate only 8, 16 or 32 items per line.
--multiples-per-line=<count>: When this is defined, the number of items written
  per dump line will be the best matching multiple of this value.
  Example: --multiples-per-line=4
  will generate 4, 8, 12, 16, 24 etc. items per line.
--power-of-2-multiples-only: When this is defined, the meaning of
  the --multiples-per-line argument is changed: In this case, not arbitrary
  multiples of that count are chosen, but only multiples that are a power of 2.
  Example: --multiples-per-line=4 --power-of-2-multiples-only
  will generate 4, 8, 16, 32 etc. items per line, but not 12, 24, 36, 40, ...
--hex-dump-prefix="string":
  Chunk dump display element displayed before the hex-dump zone.
  Defaults to '$opt_hex_dump_prefix'.
--hex-dump-item-prefix="string":
  Chunk dump display element displayed before each item in the hex dump zone.
  Defaults to '$opt_hex_dump_item_prefix'.
--ellipsis="string":
  Chunk dump display element displayed when excess chunk contents are omitted.
  Defaults to '$opt_ellipsis'.
--hex-ascii-zone-separator="string":
  Chunk dump display element displayed between the hex- and ascii-dump zones.
  Defaults to '$opt_hex_ascii_zone_separator'.
--ascii-dump-begin-indicator="string":
  Chunk dump display element displayed before the ascii-dump zone.
  Defaults to '$opt_ascii_dump_begin_indicator'.
--ascii-dump-end-indicator="string":
  Chunk dump display element displayed after the hex-dump zone.
  Defaults to '$opt_ascii_dump_end_indicator'.

$version
written by Guenther Brunthaler in 2004
END


sub indent_cols($) {
 return (defined($opt_tabwidth) ? $opt_tabwidth : 1) * shift() * $opt_indent;
}


sub indent($) {
 print((defined($opt_tabwidth) ? "\t" : ' ') x (shift() * $opt_indent));
}


sub handle_subchunks {
 my($riff, $nesting)= @_;
 our(@idstack, $seq);
 my($name, $type, $is_container, $size);
 while (($name, $is_container)= $riff->enum) {
  $size= $riff->size;
  if (defined $opt_extract) {
   my $n= $name;
   $n =~ s/\\x/0x/g;
   $n =~ s/_/0x5f/g;
   $n =~ s/~/0x7e/g;
   $n =~ tr/ /_/;
   push @idstack, $n;
   $seq= 0 unless defined $seq;
  }
  indent $nesting;
  if ($is_container) {
   $type= $riff->enter;
   printf "BEGIN %s '%s' (%#x)\n", $name, $type, $size;
   handle_subchunks($riff, $nesting + 1);
   indent $nesting;
   print "END $name '$type'\n";
   return if $riff->leave == 0;
  }
  else {
   printf "BEGIN " if defined $opt_dump;
   printf "[%s] (%#x)\n", $name, $size;
   if (defined $opt_dump) {
    my $n= $opt_linewidth;
    $n
    -= indent_cols($nesting + 1)
    + ($opt_only_ascii_dump ? 0 : length $opt_hex_dump_prefix)
    + (
     $opt_only_ascii_dump || $opt_only_hex_dump
     ? 0
     : length $opt_hex_ascii_zone_separator
    )
    + (
     $opt_only_hex_dump
     ? 0
     : length($opt_ascii_dump_begin_indicator)
     + length($opt_ascii_dump_end_indicator)
    )
    ;
    $n= int $n / (
     (
      $opt_only_ascii_dump
      ? 0
      : length($opt_hex_dump_item_prefix) + length('FF')
     )
     + (
      $opt_only_hex_dump ? 0 : length(
       $opt_url_encoding ? '%FF' : $opt_replacement_char
      )
     )
    );
    {
     my $apx;
     if (defined $opt_multiples_per_line) {
      if ($opt_power_of_2_multiples_only) {
       $apx= $opt_multiples_per_line;
       for (;;) {
        my $chal= $apx << 1;
        last unless $chal < $n && abs($n - $chal) < abs($n - $apx);
        $apx= $chal;
       }
      }
      else {
       $apx= int($n / $opt_multiples_per_line + .5);
       $apx= 1 if $apx < 1;
       $apx*= $opt_multiples_per_line;
      }
     }
     if (defined $opt_items_per_line) {
      foreach (@$opt_items_per_line) {
       $apx= $_ if !defined($apx) || abs($n - $_) < abs($n - $apx);
      }
     }
     $n= $apx if $apx;
    }
    my $bto= $riff->remaining;
    $bto= $opt_dump if $opt_dump && $opt_dump < $bto;
    unless (
     $opt_items_per_line || $opt_multiples_per_line
     || $opt_power_of_2_multiples_only
    ) {
     # Arbitrary number of items per dump line.
     $n= $bto if $n > $bto; # No unnecessary padding.
    }
    while (my $op= $bto) {
     $op= $n if $op > $n;
     my $d= $riff->read($op);
     my @d= unpack "C*", $d;
     $#d= $n - 1;
     indent $nesting + 1;
     print $opt_only_ascii_dump ? '' : $opt_hex_dump_prefix
     , $opt_only_ascii_dump
     ? ()
     : (
      map {
       $opt_hex_dump_item_prefix . (defined() ? sprintf '%02x', $_ : '  ')
      } @d
     )
     , $opt_only_ascii_dump || $opt_only_hex_dump
     ? ''
     : $opt_hex_ascii_zone_separator
     , $opt_only_hex_dump ? '' : $opt_ascii_dump_begin_indicator
     , $opt_only_hex_dump
     ? ()
     : (
      map {
        my $val= $_;
        if (defined $val) {
         $val= pack "C", $val;
         if ($opt_url_encoding) {
          $val =~ s{ \% | [^[:print:]] }{ sprintf '%%%02X', $_ }xe;
         }
         else {
          $val =~ s{ [^[:print:]] }{$opt_replacement_char}x;
         }
        }
        else {
         $val= '';
        }
        $val
      } @d
     )
     , $opt_only_hex_dump ? '' : $opt_ascii_dump_end_indicator
     , "\n"
     ;
     $bto-= $op;
    }
    if ($riff->remaining) {
     indent $nesting + 1;
     print $opt_hex_dump_prefix, $opt_hex_dump_item_prefix, $opt_ellipsis, "\n";
     $riff->skip 
    }
    indent $nesting;
    print "END [$name]\n";
   }
   if (defined $opt_extract) {
    local(*OUT);
    my($btc, $buf, $left);
    my $fname
    = $riff->filename . sprintf('~chunk~%04u~', ++$seq)
    . join('~', @idstack) . '.dat'
    ;
    open OUT, '>', $fname or die "Cannot create '$fname': $!";
    binmode OUT or die $!;
    $riff->rewind;
    $left= $opt_extract;
    while ($btc= $riff->remaining) {
     $btc= $opt_blocksize if $btc > $opt_blocksize;
     $btc= $left if $left && $btc > $left;
     $riff->read($buf, $btc, 0);
     print OUT $buf;
     if ($left) {
      last if ($left-= $btc) == 0;
     }
    }
    close OUT or die "Cannot finish '$fname': $!";
    $riff->skip if $riff->remaining;
   }
  }
  pop @idstack if defined $opt_extract;
 }
}


Getopt::Long::Configure("bundling");
my @save;
foreach (
 # Options that get the default value only if specified without the
 # optional value argument (which would override the default then).
 $opt_tabwidth
) {
 push @save, {var => \$_, old => $_};
 undef $_;
}
exit unless GetOptions(
 'h|?|help' => sub {
  print $Usage;
  die "stopped";
 }
 , 'line-width|w=i' => \$opt_linewidth
 , 'dump|d:i' => \$opt_dump
 , 'extract|x:i' => \$opt_extract
 , 'indent=i' => \$opt_indent
 , 'tab-width:i' => \$opt_tabwidth
 , 'url-encoding' => \$opt_url_encoding
 , 'replacement-char=s' => \$opt_replacement_char
 , 'only-hex-dump' => \$opt_only_hex_dump
 , 'only-ascii-dump' => \$opt_only_ascii_dump
 , 'items-per-line=s' => \$opt_items_per_line
 , 'multiples-per-line=i' => \$opt_multiples_per_line
 , 'power-of-2-multiples-only' => \$opt_power_of_2_multiples_only
 , 'hex-dump-prefix=s' => \$opt_hex_dump_prefix
 , 'hex-dump-item-prefix=s' => \$opt_hex_dump_item_prefix
 , 'ellipsis=s' => \$opt_ellipsis
 , 'hex-ascii-zone-separator=s' => \$opt_hex_ascii_zone_separator
 , 'ascii-dump-begin-indicator=s' => \$opt_ascii_dump_begin_indicator
 , 'ascii-dump-end-indicator=s' => \$opt_ascii_dump_end_indicator
 , 'block-size=i' =>\$opt_blocksize
);
foreach (@save) {
 # Restore defaults.
 ${$_->{var}}= $_->{old} if defined(${$_->{var}}) && !${$_->{var}};
}
if (defined $opt_items_per_line) {
 $opt_items_per_line= [split /\s*,\s*/, $opt_items_per_line];
}
die $Usage if @ARGV != 1;
my $riff= new Lib::RIFF($ARGV[0]);
handle_subchunks($riff, 0);
$riff->close;
