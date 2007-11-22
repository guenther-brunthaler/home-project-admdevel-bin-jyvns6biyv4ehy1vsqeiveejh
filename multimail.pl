# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/multimail.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $
# Send a number of files by e-mail using multiple separate mail sessions.


require 5.004;
use strict;
use MIME::Lite;
use MIME::QuotedPrint;
use Getopt::Long;
use POSIX qw(locale_h strftime);


my($total_mails, $log_line, $revision);
my($opt_help, @opt_to, $opt_subject, $opt_pattern, @opt_bcc, @opt_cc);
my($opt_maxsize, $opt_from, $opt_server, $opt_port, $opt_log, $opt_output);


# Usage: logevt $modes => string, string, ...
# Log a message to standard output and/or to the logfile.
# $modes contains 'action characters' in arbitrary order:
# 'O': write this message to standard output
# 'F': (also) write this message to the logfile, if any
# 'M': convert ASCII (CR, LF) sequences to newlines before output
# 'L': output a newline after the message
# 'T': Prefix any logfile output by timestamp
# The remaining 'string' arguments contain the parts of the message to
# be output and work the same as for print().
sub logevt($@) {
 my($mode, $t);
 $mode= shift;
 $t= join((defined ${,} ? ${,} : ''), @_);
 $t =~ s/\x0d\x0a/\n/g if $mode =~ /M/;
 $t.= "\n" if $mode =~ /L/;
 print $t if $mode =~ /O/;
 return unless $opt_log && $mode =~ /F/;
 my $c
 = $mode =~ /T/
 ? sprintf("[%02d:%02d:%02d] ", reverse((localtime)[0 .. 2]))
 : ''
 ;
 my @t= split /\n/, $t, -1;
 pop @t if @t > 1 && $t[-1] eq '';
 print OUT join('', map {sprintf("%5d: ", $log_line++) . "$c$_\n"} @t);
}


# Log that mail # $_[0] has been sent successfully.
# If $_[1] is present, it specifies the byte total for the attachments.
sub logsent($;$) {
 my($part, $bytes)= @_;
 $bytes= defined $bytes ? " ($bytes attachment bytes)" : '';
 logevt 'TOFL' => "Part # $part of $total_mails$bytes has been sent.";
}


sub send_mail($) {
 my $m= shift;
 $m->replace(
  'X-Mailer' => [
   "multimail.pl (Revision $revision, Author gb)"
   , 'urn:uuid:6eb002b0-240e-11d8-a231-00a0c9ef1631'
  ]
 );
 if ($opt_output) {
  print MAILDUMP $opt_output;
  $m->print(\*MAILDUMP);
 }
 else {
  $m->send;
 }
}


sub mailaddress($) {
 local($_)= shift;
 s/ ^ .* < \s* ( \S+ ) \s* > \s* $ /$1/x;
 s/ ^ .*? ( [^<">\s]+ (?: \@ [-.\w]* )? ) .* $ /$1/x;
 defined() ? $_ : 'unknown@localhost';
}


sub quote_header_field($) {
 my($s)= shift;
 my $c7= '\x21-\x3c\x3e-\x7e';
 return $s if $s =~ / ^ [$c7]+ (?: [ $c7]* [$c7]+ )? $ /xo;
 '=?ISO-8859-1?Q?'
 . join(
  ''
  , map {
   my $c= $_;
   if ($c !~ /[A-Za-z\d]/) {
    if ($c eq ' ') {$c= '_'}
    else {$c= sprintf "=%02X", ord $c}
   }
   $c;
  } split //, $s
 )
 . '?='
 ;
}


sub add_s($$) {
 my($n, $t)= @_;
 $n == 1 ? "$n $t" : "$n ${t}s";
}


my @cmdline= @ARGV;
Getopt::Long::Configure("bundling");
($revision)= '$Revision: 11 $' =~ / ( \d+ (?: [\d.]* \d+ )? ) /x;
$opt_subject= 'The files as discussed';
$opt_maxsize= 347_000;
$opt_port= 'smtp';
my $additional_mails_before= 1;
my $additional_mails_after= 1;
my $crlf= chr(13) . chr(10);
my $Usage= <<"END";
Usage: $0 [ options ]
options supported:
-h, --help: Display this help
-t <string>, --to <string>: Specify value for "To:" field. Required.
                            This option may be specified multiple times
                            for multiple receipients.
                            Form "friendy name <user\@host>" disallowed.
-f <string>, --from <string>: Specify value for "From:" field. Required.
                              Form "friendy name <user\@host>" disallowed.
-s <string>, --subject <string>: Specify value for "Subject:" field.
                                 Defaults to "$opt_subject".
                                 This value will automatically be augmented
                                 by a specification such as " (Part 4 of 10)".
-c <string>, --cc <string>: Specify value for "CC:" field.
                            Defaults to no CC receipients.
                            This option may be specified multiple times
                            for multiple receipients.
                            Form "friendy name <user\@host>" disallowed.
-b <string>, --bcc <string>: Specify value for "BCC:" field.
                             Defaults to no BCC receipients.
                             This option may be specified multiple times
                             for multiple receipients.
                             Form "friendy name <user\@host>" disallowed.
-p <string>, --prefix <string>: Specify prefix for attachments to be sent.
                                Either this option or --pattern is required.
-g <string>, --glob <string>, --pattern <string>:
             Specify filename pattern (with usual "*" or "?" wildcards)
             for attachments to be sent.
             Either this option or --prefix (-p) is required.
-m <bytes>, --maxsize <bytes>: Specify that as many attachments should be
                               packed together into one single mail until the
                               combined raw sizes (before applying any mail
                               encoding scheme such as Base64) exceed this
                               limit. Defaults to $opt_maxsize bytes. At least
                               a single attachment will always be added to each
                               mail in any case - even if that single
                               attachment is larger than this value.
--smtp-server <s>, --server <s>: Specify SMTP server address to use.
                                 Required unless --output is used.
--smtp-port <s>, --port <s>: Specify SMTP server port address to use.
                             Can be numeric or a name from /etc/services.
                             Current default is "$opt_port".
--o <file>, --output <file>: Write MIME-encoded mail output to <file>
                             instead of sending it to a mail server.
                             Required unless an SMTP server has been specified.
--log, -l: Log additional information to file "multimail.log".
--log=<file>, -l <file>: Log additional information to file <file>.
END
GetOptions(
 'h|help' => \$opt_help
 , 't|to=s' => \@opt_to
 , 'f|from=s' => \$opt_from
 , 's|subject=s' => \$opt_subject
 , 'b|bcc=s' => \@opt_bcc
 , 'c|cc=s' => \@opt_cc
 , 'm|maxsize=i' => \$opt_maxsize
 , 'p|prefix=s' => sub {shift; $opt_pattern= shift() . '*'}
 , 'g|glob|pattern=s' => \$opt_pattern
 , 'smtp-server|server=s' => \$opt_server
 , 'smtp-port|port=s' => \$opt_port
 , 'log|l:s' => \$opt_log
 , 'o|output=s' => \$opt_output
) or die $Usage;
$opt_log= 'multimail.log' if defined($opt_log) && $opt_log eq '';
if ($opt_help) {
 print $Usage;
 exit;
}
die $Usage if @ARGV;
foreach ($opt_from, \@opt_to, $opt_pattern, $opt_server) {
 if (ref $_ ? @$_ == 0 : !defined $_ || /^\s*$/) {
  die "Missing mandatory option switch!\n" . $Usage 
 }
}
foreach ($opt_from, @opt_to, @opt_cc, @opt_bcc) {
 if (mailaddress $_ ne $_) {
  die "invalid pure e-mail address '$_'";
 }
}
my @files= sort glob ${opt_pattern};
my $atts= @files;
die "There are no attachments to be sent" if $atts == 0;
my %types= (
 'zip' => 'application/x-zip-compressed'
 , 'rar' => 'application/x-rar-compressed'
 , 'jpg' => 'image/jpeg'
 , 'gif' => 'image/gif'
 , 'png' => 'image/png'
 , 'mpg' => 'video/mpeg'
);
# Create:
# $files[$MAIL_INDEX]->[$ATT_INDEX]->{fname}
# $files[$MAIL_INDEX]->[$ATT_INDEX]->{bytes}
{
 my $size;
 for (my $i= 0; $i <= $#files; ) {
  my $s= -s $files[$i];
  die "Cannot stat '$files[$i]': $!" unless defined $s;
  if ($i > 0 && ($size+= $s) <= $opt_maxsize) {
   push @{$files[$i - 1]}, {fname => $files[$i], bytes => $s};
   splice @files, $i, 1;
  }
  else {
   $files[$i]= [{fname => $files[$i], bytes => $size= $s}];
   ++$i;
  }
 }
}
$total_mails= $additional_mails_before + @files + $additional_mails_after;
if ($opt_log) {
 open OUT, '>>', $opt_log or die "Cannot open log file '$opt_log': $!";
 $log_line= 1;
 {
  my @d= reverse((localtime)[3 .. 5]);
  $d[0]+= 1900; ++$d[1];
  logevt 'FL';
  logevt 'TFL'
  => sprintf "Date %04d-%02d-%02d. Starting new session.", @d
  ;
  logevt 'FL';
 }
 foreach (
  ['commandline argument', \@cmdline]
  , ['pattern', $opt_pattern]
  , ['subject', $opt_subject]
  , ['from', $opt_from]
  , ['to', \@opt_to]
  , ['cc', \@opt_cc]
  , ['bcc', \@opt_bcc]
  , ['smtp-server', $opt_server]
  , ['smtp-port', $opt_port]
  , ['output', $opt_output]
  , ['maxsize', $opt_maxsize]
 ) {
  my($k, $v)= @$_;
  if (ref $v) {
   for (my $i= 0; $i < @$v; ++$i) {
    my $e= $v->[$i];
    $e= defined $e ? $e eq '' ? '(empty string)' : qq'"$e"' : '(unspecified)';
    logevt 'FL' => "${k} # " . ($i + 1) . " := $e";
   }
  }
  else {
   $v= defined $v ? $v eq '' ? '(empty string)' : qq'"$v"' : '(unspecified)';
   logevt 'FL' => "$k := $v";
  }
 }
 logevt 'FL';
}
if ($opt_output) {
 open MAILDUMP, '>', $opt_output
 or die "Cannot create output file '$opt_output': $!"
 ;
 binmode MAILDUMP or die;
 logevt 'TFL', "Mails will be redirected into file '$opt_output'";
 logevt 'FL';
 $opt_output= mailaddress $opt_from;
 my $old= setlocale(LC_TIME);
 setlocale(LC_TIME, "C");
 $opt_output
 = "From $opt_output  " . strftime "%a %b %e %H:%M:%S %Y$crlf", localtime
 ;
 setlocale(LC_TIME, $old);
}
else {
 MIME::Lite->send($opt_port, $opt_server, Timeout => 60);
}
my @common_headers= (
 From => $opt_from
 , To => \@opt_to
 , Cc => \@opt_cc
 , Bcc => \@opt_bcc
);
my $att= 1;
{
 my $text
 = "This mail is the first mail from a total of $total_mails mails" . $crlf
 . "that will be sent to you." . $crlf . $crlf
 . "(This first mail is purely informational; it does not have" . $crlf
 . "any attachments.)"
 . $crlf . $crlf
 . "The following lines provide an overview of the attachments" . $crlf
 . "that will be sent in the remaining mails." . $crlf . $crlf
 ;
 my $bytes= 0;
 my $s;
 for (my $mi= 0; $mi < @files; ++$mi) {
  for (my $ai= 0; $ai < @{$files[$mi]}; ++$ai) {
   $s= "Attachment # " . $att++
   . qq' (file "$files[$mi]->[$ai]->{fname}", '
   . add_s($files[$mi]->[$ai]->{bytes}, 'byte') . ') will be sent in "Part '
   . ($mi + $additional_mails_before + 1) . qq' of $total_mails"'
   ;
   $text.= $s . $crlf;
   logevt 'FL' => $s;
   $bytes+= $files[$mi]->[$ai]->{bytes};
  }
 }
 $s
 = $crlf . 'Accumulated size of all'
 . (
  $att - 1 == 1
  ? ''
  : ' ' . ($att - 1)
 )
 . ' attachments: ' . add_s($bytes, 'byte') . '.' . $crlf
 ;
 logevt 'FML' => $s;
 $text.= $s;
 my $msg= MIME::Lite->new(
  @common_headers
  , Subject => quote_header_field "$opt_subject (Part 1 of $total_mails)"
  , Type =>'text/plain'
  , Data => $text
 );
 send_mail $msg;
 logsent 1;
}
$att= 1;
for (my $ms= 0; $ms <= $#files; ++$ms) {
 my $index= $ms + $additional_mails_before + 1;
 my $msg= MIME::Lite->new(
  @common_headers
  , Subject => quote_header_field "$opt_subject (Part $index of $total_mails)"
  , Type =>'multipart/mixed'
 );
 my $bytes= 0;
 my $text
 = "This is mail $index of a total of $total_mails mails," . $crlf
 . "containing attachments $att through " . ($att + @{$files[$ms]} - 1)
 . ' from a total of ' . add_s($atts, 'attachment') . '.' . $crlf . $crlf
 . "A list of attachments for this mail follows." . $crlf . $crlf
 ;
 for (my $i= 0; $i < @{$files[$ms]}; ++$i) {
  $bytes+= $files[$ms]->[$i]->{bytes};
  $text.= "Attachment # " . $att++ . qq': file "$files[$ms]->[$i]->{fname}", '
  . add_s($files[$ms]->[$i]->{bytes}, 'byte') . '.' . $crlf
  ;
 }
 $text.= $crlf
 . 'Total size for all attachments for this mail: '
 . add_s($bytes, 'byte') . '.' . $crlf
 ;
 $msg->attach(Type => 'TEXT', Data => $text);
 for (my $i= 0; $i < @{$files[$ms]}; ++$i) {
  my $name= $files[$ms]->[$i]->{fname};
  my $type= $name =~ /\.([^.]+)$/;
  $type= '' unless defined $type;
  $type= $types{lc $type};
  $type= 'application/octet-stream' unless defined $type;
  $msg->attach(
   Type => $type, Path => $name, Filename => $name, Disposition => 'attachment'
  );
 }
 send_mail $msg;
 logsent $index, $bytes;
}
{
 my $msg= MIME::Lite->new(
  @common_headers
  , Subject
  => quote_header_field "$opt_subject (Part $total_mails of $total_mails)"
  , Type =>'text/plain'
  , Data
  => "This mail merely indicates that all of the $total_mails mails" . $crlf
  . "have been sent successfully. (It does not necessarily guarantee" . $crlf
  . "that all mails have also been received successfully on your side," . $crlf
  . "however.)" . $crlf . $crlf
  . "This mail has been the last one; no more mails will follow." . $crlf
  . $crlf
  . "This mail is purely informational; it does not have any attachments."
  . $crlf
 );
 send_mail $msg;
 logsent $total_mails;
}
logevt 'FL';
close MAILDUMP or die if $opt_output;
logevt 'TFL', 'End of Session.';
close OUT or die if $opt_log;
