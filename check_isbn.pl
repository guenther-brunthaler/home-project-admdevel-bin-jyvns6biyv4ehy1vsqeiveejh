# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $Archive: /PRIVATE/GB/DATA/txt/Ansi/STRANDED.TXT $
# $Author: root(xternal) $
# $Modtime: 30.10.00 23:34 $ (DOLM)
# $Date: 2006-11-06T23:14:31.537884Z $ (Updated)
# $Revision: 11 $
# $Nokeywords:$
# $xsa1$

# ISBN verifier
# written in 2000 by Guenther Brunthaler


use strict;
use Getopt::Long;

my $Usage= <<"_E_N_D_";
$0 verifies ISBNs occurring in a text.
Usage: $0 <file> ... [-v | --verbose]
       $0 -? | -h | --help
where
<file>: one or more files to be verified. If missing, standard input is used.
-v, -verbose: All ISBNs will be reported, not only malformed ones.
-?, -h, --help: display this help
_E_N_D_

my($errs, $isbns, $oldisbn, $newisbn, $isbn, @isbn, $sum, $newcheck, $i);
my($help, $verbose);

format STDOUT_TOP=
+========================+========+==========+
|        |         Check | Should |    Is    |
| Item # | ISBN    Digit |   Be   |    OK    |
+========================+========+==========+
.

my $STDOUT_FOOTER= <<".";
+========================+========+==========+
.

format=
| @>>>>> | @<<<<<<<<<<<< | @||||| | @||||||| |
  $isbns,  $oldisbn,       $newcheck, $oldisbn eq $newisbn ? 'yes' : '***NO***'
.

Getopt::Long::Configure("bundling");
GetOptions('h|help|?' => \$help, 'v|verbose' => \$verbose);

if ($help) {
 print $Usage;
 exit;
}

my $magic= 11;
$errs= $isbns= 0;
while (<>) {
 while (
  m{
   \b
   (?:
    # 'ISBN'-tag followed by digit string only allowing improper formatting
    ISBN \s* (
     # the number starts with a numeric digit
     \d
     # being followed by exactly eight occurrences of
     (?:
      # an optional dash-character before a
      -?
      # a single numeric digit
      \d
     ){8}
     # being followed by exactly one optional dash-character before a
     -?
     # a single check digit
     [\dX]
    )
    |
    # correctly formatted numeric/slash-separated form only
    (
     \d-\d\d\d-\d\d\d\d\d-[\dX]
    )
   )
   \b
  }gix
 ) {
  $isbn= defined($1) ? $1 : $2;
  $isbn=~ s/-//g;
  @isbn= split //, $isbn;
  $oldisbn= sprintf("%d-%d%d%d-%d%d%d%d%d-%d", @isbn);
  die unless @isbn == 10;
  pop @isbn;
  $sum= 0;
  for ($i= 0; $i < 9; ++$i) {
   $sum+= $isbn[$i] * (10 - $i);
  }
  $newcheck= ($magic - ($sum % $magic)) % $magic;
  $newcheck= 'X' if $newcheck == 10;
  $newisbn= sprintf("%d-%d%d%d-%d%d%d%d%d-%d", @isbn, $newcheck);
  if ($oldisbn ne $newisbn) {
   print "Wrong ISBN $oldisbn: should be $newisbn!\n" unless $verbose;
   ++$errs;
  }
  ++$isbns;
  write if $verbose;
 }
}
print $STDOUT_FOOTER if $verbose;
print "$isbns total ISBNs have been found; $errs errors encountered.\n";
