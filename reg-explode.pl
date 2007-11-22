# Explode "hex:"-entries in Windows .reg-Files into "file:"-entries
# referring to decoded external files which will be created.
# Can also be used to convert back the exploded format into the
# "hex:"-format.
#
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/reg-explode.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Getopt::Std;


sub HELP_MESSAGE {
 print << ".";
Usage: $0 [ options ... ] <reg-file> ...

$0 explodes Windows Registry '.reg'-files into an alternative form
where 'hex:'-entries will refer to external binary files which
can be directly edited by any hex editor.
$0 can also convert the exploded files back into the original
RegEdit format.

$0 can read '.reg'-files in either and even in mixed formats.

In absence of the -i option, the skripts will be converted into
the exploded form.

When exploding, the exploded files will have the same name as the
input file, with "-N" appended, where "N" is an integer.

Options:
-i: "Implode". Convert input files into standard RegEdit format.
    Any binary files containing referenced content will be removed
    after their contents have successfully been included within the
    output files.
-v: Use verbose diagnostics.
--help: Show this help.
.
}


my(%opt);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 11 $' =~ /(\d[\d.]*)/;
getopts('i', \%opt) or die;
