# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/clonevdubjobs.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# Clones VirtualDub Job files.

=clonevdubjobs user's guide

 What is clonevdubjobs.pl and what can I use it for?
 
 clonevdubjobs.pl is a Perl script that takes a saved VirtualDub .jobs
 file as an input template file.
 
 It then creates a new .jobs file from the template file by replacing
 all occurrences of the original filename of the jobs by new ones.
 
 If more then one new filename is specified, then all the jobs in
 the template are repeated for each additional filename as well.
 
 The resulting .jobs file can then be loaded into VirtualDub and run there.
 
 An example will explain what I am using this tool for:
 
 I am frequently creating a bunch of related .avi files from a common
 source that should be encoded as DivX files, all using the same settings.
 
 For that, I open the first of the .avi files, say, "file1.avi", set up
 filters, disable audio and set up the DivX codec for the 1st pass.
 
 Then I save the resulting file as "file1-1.avi" to VirtualDub's job list.
 
 Now I set up audio compression and set the DivX codec for the second pass.
 
 Next I save this as a second job into file "file1-2.avi".
 
 Without my tool, now I had to repeat the above settings for all additional
 files such as "file2.avi", "file3.avi" etc.
 
 But instead, I now can save the two jobs into a file, say "file_old.jobs".
 
 Then I run my tool with the following command line:

 clonevdubjobs.pl file_old.jobs file_new.jobs file1 file1 file2 file3 file4
 
 and the file "file_new.jobs" will be created, containing 8 jobs, being
 4 modified copies of the 2 jobs from "file_old.jobs".
 
 Now I can load the new .jobs file into VirtualDub's job list and let
 it execute.
 
 How does it work?
 
 The script takes the input jobs file, and for all jobs in the input file,
 replaces the specified search string ("file1" in my example) with the
 first of the replacement strings.
 
 Then it adds all the jobs from the input file again, but this time replacing
 the search string with the second replacement string.
 
 This continues as often as the number of replacement strings.
 
 In addition to this, the script automatically modifies the $job and $numjobs
 statements as required.
 
 Caveat: Take care that the search string does not also refer to some
 other part of the .jobs file than those referring to file names.
 For the most part, this tool is just a batch text replacer.
 Nevertheless, it works and can save one a huge amount of work.
 
 Note: I advise editing the saved VirtualDub jobs file before replicating 
 its jobs. The reason is that such a jobs file may typically contain 
 (unnecessary) references to the number of frames / movie length that only 
 refer to the original movie file. In order to remove those references, 
 edit the jobs file in an editor and move the "VirtualDub.subset.Clear();" 
 line before the "VirtualDub.Open(" line. Remove the 
 "VirtualDub.subset.Add" lines. Also remove any lines between
 "// $output" and "// $script" that contain log messages or absolute time 
 readings.

=cut

use strict;
use Fcntl qw(:DEFAULT :seek);


die <<"---" if @ARGV < 4 || !-f $ARGV[0];
Usage: $0 <infile.jobs> <outfile.jobs> <search_string> <replacement_1> ...
where
<infile.jobs>: A VirtualDub .jobs file to be cloned
<outfile.jobs>: A VirtualDub .jobs file to be created by cloning
<search_string>: A substring to search for in the .jobs file
<replacement_1>: Will substitute <search_string> for the first cloned copy.
Additional replacement strings will add more clones of <file.jobs> to output.
---
my($srch, $body, $rplc, $nj, $off);
open IN, '<', shift @ARGV or die $!;
open OUT, '>', shift @ARGV or die $!;
$srch= quotemeta shift @ARGV;
$srch= qr/$srch/;
for (;;) {
 $_= <IN>;
 die "missing \$numjobs statement" unless defined;
 if (/(^.*\$numjobs\s+)(\d+)(.*?)$/) {
  print OUT $1 . ($nj= $2) * @ARGV . $3, "\n";
  last;
 }
 print OUT;
}
$body= tell IN;
for ($off= 0; ; $off+= $nj) {
 $rplc= shift @ARGV;
 for (;;) {
  $_= <IN>;
  die "missing \$done statement" unless defined;
  last if m!^//\s*\$done!;
  if (m!^(//\s+\$job\s+"Job\s+)(\d+)(.*?)$!) {
   $_= $1 . ($2 + $off) . $3 . "\n";
  }
  else {
   s/$srch/$rplc/g;
  }
  print OUT;
 }
 last if @ARGV == 0;
 seek IN, $body, SEEK_SET or die $!;
}
print OUT;
while (<IN>) {
 print OUT;
}
close OUT or die $!;
close IN or die $!;
