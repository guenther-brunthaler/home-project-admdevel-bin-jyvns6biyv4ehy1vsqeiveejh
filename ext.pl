#! /usr/bin/perl
# Returns a sorted list of the lowercased file extensions
# from all the files in the input file list.
while (<>) {
 $x{lc $1}= 0 if /\.([^.]+)$/;
}
END {
 foreach (sort keys %x) {
  print;
 }
}
