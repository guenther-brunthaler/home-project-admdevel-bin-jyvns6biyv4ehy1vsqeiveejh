#! /usr/bin/perl
# Report missing files in a numbered sequence of files.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/missing.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use Getopt::Long;
use File::Spec;


our $opt_pattern;
our $opt_from;
our $opt_to;
our $opt_step= 1;
our $opt_invert;
our $opt_verbose;


my $version= '$Revision: 2647 $ $Date: 2006-08-26T07:45:40.216781Z $';
$version =~ s/
 .+? Revision: \s+ ([^\$\s]+)
 .+ Date: \s+ ([^\$]+?)
 \s+ \$
/Version $1, $2/x
;
my $Usage= <<"END";
$0 - report missing files in a numbered sequence of files.
Usage: $0 (--help | -h)
Usage: $0 [options] [<pattern>]
where
<pattern> : File pattern to scan for. May contain either a fixed number
 of '#' for matching exactly that many decimal digits at that position.
 '#' can optionally be followed by "{<low>,<high>}", where
 <low> is the minimum number and <high> is the maximum number of decimal
 digits required at that position.
 Note that "{" and "}" are not treated specially in any other context.
 In order to include a literal "#", use the special notation "#{0}".
 Writing "{<num>}" is a shortcut for writing "{<num>,<num>}".
 Special convenience functionality: Insteady of writing '#' as a wildcard
 for a numeric digit, writing any numeric digit will do the same! But ONLY
 if no actual '#' occurs within the pattern. In that case, only the '#' are
 considered to be wildcard characters.
 The "#{...}"-syntax also works for writing '#' as wildcard characters only.
 A special case arises if there is more than one sequence of decimal
 digits within the pattern. In this case, the longest sequence only is
 assumed to be wildcard characters; any remaining sequences are interpreted
 literally.
 If there are multiple decimal digit sequences of the same length, the
 last such sequence is chosen.
 The same rules also apply when writing more than one sequence of '#'.
 Also note that it is allowed for <pattern> to include a path specification.
 If no such path specification is included within <pattern>, it will be
 matched against the contents of the current directory.
 Wildcards are only allowed within the filename portion of the pattern,
 not within the path name portion.
 Example: "#{1,3}" will match one to three decimal digits.
 Example: "PICT####.JPG" is the same as "PICT#{4}.JPG".
 Example: "PICT0719.JPG" is also the same as "PICT####.JPG".
 Example: "series_2_0719.jpg" is the same as "series_2_####.jpg".

Note that <pattern> is optional. If it is not specified, the first
appropriate filename in the current directory is used as the pattern. A
filename is appropriate if it contains a sequence of decimal digits.
If more than one sort of pattern could be selected that way, the one with
the longest sequence of decimal digits is used as long as there is only a
single pattern with that sequence length. Otherwise, the default pattern
determination will not work and an error will be reported.

Options:
--help, -h, -?: display this help
--from <integer>, -f <integer>:
  The lowest number of the numbered sequence to check for.
  If not specified, the lowest number found in the set of all matching
  file names is assumed to be that lowest sequence number.
--to <integer>, -t <integer>:
  The highest number of the numbered sequence to check for.
  If not specified, the highest number found in the set of all matching
  file names is assumed to be that highest sequence number.
--step <integer>, -s <integer>:
  The increment step for the sequence numbers to scan for.
  For instance, "--from 1 --to 7 --step 2" would check for 1, 3, 5 and 7.
  Must be a positive number. Defaults to $opt_step.
--invert, -i:
  Invert search results. Disabled by default.
  Lists the existing files that match instead of the missing ones.
--verbose, -v: Print additional diagnostic messages while processing.

$version
written by Guenther Brunthaler in 2004
END


# Extracts information from a pattern specification.
# Arguments: <pattern>, <raw>
# where
# <pattern>:
#  The pattern optionally containing '#' or decimal digits as wildcards.
# <raw>:
#  Boolean indicating that any '#' encountered within the pattern
#  are to be interpreted literally rather than as wildcards.
#
# Returns (<canonpat>, <length>, <prefix>, <suffix>, <regex>)
# where
# <canonpat>:
#  Canonical representation of the input pattern. Can be used to compare
#  multiple patterns in order to see whether they are identical.
#  For case-insensitive file systems, all characters that have different
#  upper and lower letter case representations will be mapped to lower case.
# <length>:
#  The minimum number of wildcard characters that have to match
#  decimal digits.
# <prefix>: The part of <canonpat> before the wildcard specification.
# <suffix>: The part of <canonpat> after the wildcard specification.
#  Will be 0 if the input pattern does not have any wildcards.
# <regex>:
#  Regular expression for performing the pattern search. This includes
#  the regex /i option if the file system is case-insensitive.
sub convert_pattern($;$) {
 my($pat, $raw)= @_;
 my($bmin, $bmax, $bi, $blen, $prefix, $suffix);
 $bmin= $bi= $blen= $bmax= 0;
 if (!$raw && $pat =~ /#/) {
  # Pattern with '#' wildcards.
  my($ci, $cmin, $cmax, $clen, $cwlen);
  foreach (
   $pat =~ /
    ( \#+ ) # \$1.
    (?:
     { \s*
     ( \d+ ) # \$2.
     (?:
      \s* , \s*
      ( \d* ) # \$3.
     )?
     \s* }
    )?
   /gx
  ) {
   ($clen, $ci, $cwlen, $cmin, $cmax)= (
    $+[0] - $-[0], $-[0], $+[1] - $-[1], $2, $3
   );
   $cmin= 1 unless defined $cmin;
   $cmax= $cmin unless defined $cmax;
   die if $cmin < 1 || $cmax ne '' && $cmax < $cmin;
   # Either one '#' is consumed by the following '{...}',
   # or $cmin == 1 must be subtracted before adding $cwlen.
   $cmin+= --$cwlen;
   $cmax+= $cwlen if $cmax ne ''; # Empty string means infinity.
   if ($cmax eq '' || $cmax >= $bmax) {
    ($bmin, $bmax, $bi, $blen)= ($cmin, $cmax, $ci, $clen);
   }
  }
 }
 elsif ($pat =~ /\d/) {
  # Pattern with decimal digits wildcards.
  my $clen;
  foreach ($pat =~ /\d+/g) {
   $clen= $+[0] - $-[0];
   ($blen, $bi)= ($clen, $-[0]) if $clen >= $blen;
  }
  $bmin= $bmax= $blen;
 }
 my $regex
 = '^'
 . quotemeta(substr $pat, 0, $bi)
 . ($bmin > 0 ? "(\\d{$bmin,$bmax})" : '')
 . quotemeta(substr $pat, $bi + $blen)
 . '$'
 ;
 $pat= ($prefix= substr $pat, 0, $bi)
 . ($bmin > 0 ? "#{$bmin,$bmax}" : '') 
 . ($suffix= substr $pat, $bi + $blen)
 ;
 if (File::Spec->case_tolerant) {
  $regex= '(?i)' . $regex;
  $pat= lc $pat;
 }
 ($pat, $bmin, $prefix, $suffix, qr/$regex/);
}


Getopt::Long::Configure("bundling");
exit unless GetOptions(
 'h|?|help' => sub {
  print $Usage;
  die "stopped";
 }
 , 'from|f=i' => \$opt_from
 , 'to|t=i' => \$opt_to
 , 'step|s=i' => \$opt_step
 , 'invert|i' => \$opt_invert
 , 'verbose|v' => \$opt_verbose
);
my $pattern= shift;
die $Usage if @ARGV != 0;
my($base, $blen, $re, $prefix, $suffix);
# Determine base directory.
# Make pattern a basename pattern.
if (defined($pattern) && $pattern gt '') {
 $pattern= File::Spec->canonpath($pattern);
 my($vol, $dir);
 ($vol, $dir, $pattern)= File::Spec->splitpath($pattern, -d $pattern);
 $dir= File::Spec->curdir if $dir eq '';
 $base= File::Spec->catpath($vol, $dir, '');
}
else {$base= File::Spec->curdir}
if ($opt_verbose) {
 print qq'Base directory = "', File::Spec->canonpath($base), qq'".\n';
}
if (defined($pattern) && $pattern gt '') {
 ($pattern, $blen, $prefix, $suffix, $re)= convert_pattern $pattern;
}
else {
 # Automatically determine filename pattern.
 opendir DIR, $base or die "Cannot read directory '$base': $!";
 my($coll, $cpat, $cre, $clen, $cprefix, $csuffix);
 $blen= 0; $pattern= '';
 while (defined($_= readdir DIR)) {
  next unless -f File::Spec->catfile($base, $_);
  ($cpat, $clen, $cprefix, $csuffix, $cre)= convert_pattern $_, 1;
  if ($clen >= $blen && $cpat ne $pattern) {
   # New default pattern is better or same.
   unless ($coll= $clen > 0 && $clen == $blen) {
    # Better.
    ($pattern, $re, $blen, $prefix, $suffix)
    = ($cpat, $cre, $clen, $cprefix, $csuffix)
    ;
   }
  }
 }
 closedir DIR or die $!;
 if ($blen == 0) {
  die "Could not find any suitable default pattern:"
  . " Please specify manually"
  ;
 }
 if ($coll) {
  die "Cannot unambigously determine default pattern:"
  . " Please specify manually"
  ;
 }
 print "Using default basename pattern '$pattern'.\n" if $opt_verbose;
}
my(%i, $i);
opendir DIR, $base or die "Cannot read directory '$base': $!";
while (defined($_= readdir DIR)) {
 next unless -f File::Spec->catfile($base, $_) && /$re/ && defined $1;
 if (exists $i{$i= $1 + 0}) {
  die "Multiple directory entries matching the same basename pattern: '$_'";
 }
 $i{$i}= $_;
}
closedir DIR or die $!;
unless (defined($opt_from) && defined($opt_to)) {
 my($lowest, $highest);
 foreach (keys %i) {
  if (defined $lowest) {
   $lowest= $_ if $_ < $lowest;
   $highest= $_ if $_ > $highest;
  }
  else {
   $lowest= $highest= $_
  }
 }
 $opt_from= $lowest unless defined $opt_from;
 $opt_to= $highest unless defined $opt_to;
}
for ($i= $opt_from; $i <= $opt_to; $i+= $opt_step) {
 if (exists $i{$i} ? $opt_invert : !$opt_invert) {
  my $n= $i{$i};
  $n= sprintf '%s%0*u%s', $prefix, $blen, $i, $suffix unless defined $n;
  $n= File::Spec->catfile($base, $n) if $base ne File::Spec->curdir;
  print "$n\n";
 }
}
print "(no items listed)\n" if $opt_verbose && !%i;
