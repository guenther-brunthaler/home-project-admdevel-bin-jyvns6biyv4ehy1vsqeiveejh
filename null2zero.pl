#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$


# Reads a tabulator-separated text file from standard input and writes the same
# file back to standard output; except that 0 is written into all previously empty fields.
while (defined($_= <STDIN>)) {
 s/^\t/0\t/;
 while (s/\t\t/\t0\t/g) {};
 s/\t$/\t0/;
 print;
}
