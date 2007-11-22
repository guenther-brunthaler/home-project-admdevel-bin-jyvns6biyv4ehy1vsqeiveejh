# Extract relevant information from *.msv SONY IC Voice Recorder files.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/sonyicinfo.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::CSV_bz2d9x40wnlfxlpt9chgq5982;
use File::Find;


# Print an array of strings as a valid Microsoft CSV line.
sub print_csv(\@) {
 print Lib::list2csv(@{(shift)}), "\n";
}


if ($ARGV[0] =~ /--help|-h|\/\?/) {
 print
 "$0 - Extract Information from SONY *.msv IC Recorder files\n"
 , "Usage: $0 [ -f | <outname>.csv ]\n"
 , "where\n"
 , "-f: filter mode - writes to standard output.\n"
 , "<outname.csv>: The filename of the output file.\n"
 , "Without arguments, the output will be written to \"new.csv\".\n"
 ;
 exit;
}
my $out= @ARGV == 1 ? $ARGV[0] eq '-f' ? undef : $ARGV[0] : 'new.csv';
if (defined $out) {
 open OUT, '>', $out or die "Cannot create '$out': $!";
 select OUT;
}
my(@h, @v);
@h= qw/         name    user  year month day hour minute second/;
my $format= '@162 Z* @434 Z* @52 n     C   C    C      C      C';
print_csv(@{['file name', @h]});
find(
 sub {
  return unless /.\.msv$/i;
  my $buf;
  open IN, '<', $_ or die $!;
  binmode IN or die;
  die unless read(IN, $buf, 0x200) == 0x200;
  close IN or die;
  my $n= $File::Find::name;
  $n =~ s/^.[\\\/]//;
  @v= unpack $format, $buf;
  unshift @v, $n;
  print_csv(@v);
 }
 , '.'
);
if (defined $out) {
 select;
 close OUT or die $!;
}
