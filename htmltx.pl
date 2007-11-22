# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2647 $
# $Date: 2006-08-26T07:45:40.216781Z $
# $Author: gb $
# $State$
# $xsa1$

# HTML table extractor


use strict;
use Getopt::Std;


my $Usage= <<"__egasU";
$0 extracts the contents of an HTML file into a text file

Usage: $0 [ -u ] [ <infile> [ <outfile> ]]
where
-u: Create output file in UTF-8 format instead of default character set
<infile>: name of the html-format input file (default: stdin)
<outfile>: name of the text-format output file (default: stdout)

The generated output will have the following format:
<table>, <row>, <column>, <contents>
where the fields are tab-separated and each tabs in the fields
will be replaced by spaces. Furthermore, leading and trailing spaces
will be removed and multiple spaces will be compressed to a single one.
<table>, <row> and <column> are all zero-based values.
<table> is the number of the table; 0 means text outside any table
<row> means paragraph number outside a table or a table row index
<column> is always 0 for text outside a table or the cell column number
__egasU


my($html_next_char, $html_have_nc, $html_buf_sl, $html_buf_cp, $html_buf);


sub report {
   my($out, $t, $nref, $rref, $cref, $bufref)= @_;
   if ($$bufref ne '') {
      print $out "$$nref[$t]\t$$rref[$t]\t$$cref[$t]\t$$bufref\n";
      $$bufref= '';
      ++$$rref[$t] if !$t;
   }
}


sub get_html_token($) {
   my $fh= shift;
   my($token, $c);
   &skip_ws($fh);
   if (($token= &get_char($fh)) eq '<') {
      # fetch HTML tag
      do {
         $token.= ($c= &get_char($fh));
      } until ($c eq '>');
      normalize_string($token);
   }
   elsif (defined($token)) {
      # fetch text up to the next HTML tag or EOF
      $token.= $c while (defined($c= &get_char($fh)) && $c ne '<');
      &unget_char($c);
      &decode_chars($token);
      normalize_string($token);
   }
   return $token;
}


sub unget_char {
   $html_next_char= $_[0];
   $html_have_nc= 1;
}


sub get_char {
   my($fh)= @_;
   if ($html_have_nc) {
      $html_have_nc= 0;
      return $html_next_char;
   }
   while (!defined($html_buf_cp) || $html_buf_cp >= $html_buf_sl) {
      return undef if !defined($html_buf= <$fh>);
      $html_buf_sl= length $html_buf,
      $html_buf_cp= 0;
   }
   return substr $html_buf, $html_buf_cp++, 1;
}


sub skip_ws {
   my($fh)= @_;
   my($c);
   while (defined($c= &get_char($fh))) {
      last unless $c=~ /\s/;
   }
   &unget_char($c);
}


sub decode_chars {
   $_[0]=~ s/&Aacute;/Á/g;
   $_[0]=~ s/&Eacute;/É/g;
   $_[0]=~ s/&Iacute;/Í/g;
   $_[0]=~ s/&Oacute;/Ó/g;
   $_[0]=~ s/&Uacute;/Ú/g;
   $_[0]=~ s/&aacute;/á/g;
   $_[0]=~ s/&eacute;/é/g;
   $_[0]=~ s/&iacute;/í/g;
   $_[0]=~ s/&oacute;/ó/g;
   $_[0]=~ s/&uacute;/ú/g;
   $_[0]=~ s/&auml;/ä/g;
   $_[0]=~ s/&ouml;/ö/g;
   $_[0]=~ s/&uuml;/ü/g;
   $_[0]=~ s/&Auml;/Ä/g;
   $_[0]=~ s/&Ouml;/Ö/g;
   $_[0]=~ s/&Uuml;/Ü/g;
   $_[0]=~ s/&szlig;/ß/g;
   $_[0]=~ s/&amp;/&/g;
   $_[0]=~ s/&gt;/>/g;
   $_[0]=~ s/&lt;/</g;
   $_[0]=~ s/&nbsp;/ /g;
   $_[0]=~ s/&deg;/°/g;
   $_[0]=~ s/&sup3;/³/g;
   $_[0]=~ s/&sup2;/²/g;
   $_[0]=~ s/&#(\d+);/ chr $1 /ge;
   die "unknown char encoding '$_[0]'" if $_[0] =~ /&.+;/;
}


sub normalize_string($) {
   $_[0]=~ s/^\s*(.*?)\s*$/$1/;
   $_[0]=~ s/\s/ /g;
   do 0 while $_[0]=~ s/\s{2}/ /g;
}


sub extract_tables($$) {
   my($in, $out)= @_;
   my($token);
   if (defined($token= get_html_token($in))) {
      unless ($token=~ /^<HTML>$/i) {
         last unless defined($token= get_html_token($in));
      }
      my($t, @r, @c, @n, $nn, $buf);
      $r[0]= $c[0]= $n[0]= $nn= $t= 0; $buf= '';
      while (defined($token= get_html_token($in)) && $token!~ m(^</HTML>$)i) {
         #print $out "<<<$token>>>\n\n"; next;
         if (substr($token, 0, 1) eq '<') {
            # HTML-tag
            if ($token=~ /^<TABLE[\s>]/i) {
               # start a new table
               &report($out, $t, \@n, \@r, \@c, \$buf);
               ++$t; $r[$t]= $c[$t]= -1; $n[$t]= ++$nn;
            }
            elsif ($t > 0) {
               # inside a table
               if ($token=~ m(^</TABLE[\s>])i) {
                  &report($out, $t, \@n, \@r, \@c, \$buf);
                  die "unbalanced </TABLE>" if --$t < 0;
               }
               elsif ($token=~ /^<TR[\s>]/i) {
                  &report($out, $t, \@n, \@r, \@c, \$buf);
                  ++$r[$t]; $c[$t]= -1;
               }
               elsif ($token=~ /^<T[DH][\s>]/i) {
                  &report($out, $t, \@n, \@r, \@c, \$buf);
                  ++$c[$t];
               }
            }
            else {
               # outside any table
               if ($token=~ /^<(?:P|BR)[\s>]/i) {
                  &report($out, $t, \@n, \@r, \@c, \$buf);
               }
            }
         }
         else {
            # HTML-text
            $buf.= ' ' if $buf ne '';
            $buf.= $token;
         }
      }
      # output last text block
      &report($out, $t, \@n, \@r, \@c, \$buf);
   }
}


my($in, $out, %opt);
$Getopt::Std::STANDARD_HELP_VERSION= 1;
our($VERSION)= '$Revision: 2647 $' =~ /(\d[\d.]*)/;
getopts('uv', \%opt) or die;
if ($#ARGV >= 0) {
   open IN, "<$ARGV[0]" or die "$Usage";
   $in= *IN{IO};
}
else {
   $in= *STDIN{IO};
}
if ($#ARGV >= 1) {
   open OUT, '>', $ARGV[1] or die "$Usage";
   $out= *OUT{IO};
}
else {
   $out= *STDOUT{IO};
}
if ($opt{u}) {
   binmode $out, 'utf8';
   print $out chr 0xfeff; # Write BOM.
}
extract_tables $in, $out;
close IN or die if $#ARGV >= 0;
close OUT or die if $#ARGV >= 1;
