# Write information about AVI files to standard output.
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/aviinfo.pl 2647 2006-08-26T07:45:40.216781Z gb  $


use strict;
use FindBin;
use lib "$FindBin::Bin";
use Lib::RIFF_C19F8B63_C093_11D8_9140_00A0C9EF1631;
use Lib::SimpleParser_8AEE1C20_CBA0_11D5_9920_C23CC971FBD2;


our($semicolon, $closing_c_remark, $closing_cpp_remark);


our %o;
format REPORT_HEADER=
 ~^|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||~
qq'*** Report: "$o{title}" ***'

Name           Contents      Description
===============================================================================
.
format REPORT_BODY=
^>>>>>>>>>>>>> ^<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$o{name},      $o{value},    $o{desc}
^>>>>>>>>>>>>>~^<<<<<<<<<<<<~^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$o{name},      $o{value},    $o{desc}
.
format REPORT_FOOTER=
===============================================================================
.


sub report($\%) {
 my($title, $struct)= @_;
 local($~, $:);
 $:= " \n-_";
 $~= 'REPORT_HEADER'; $o{title}= $title; write;
 $~= 'REPORT_BODY';
 my($oa, $ob, $oc);
 foreach (
  sort {
   ($oa, $ob)= (
    $struct->{'$'}->{$a}->{offset}, $struct->{'$'}->{$b}->{offset}
   );
   if (defined $oa) {
    if (defined $ob) {$oc= $oa <=> $ob}
    else {$oc= -1}
   }
   elsif (defined $ob) {$oc= +1}
   else {$oc= $a cmp $b}
   $oc;
  } grep !/\$/, keys %$struct
 ) {
  %o= (
   name => $_
   , value => $struct->{$_}
   , desc => $struct->{'$'}->{$_}->{desc}
  );
  write;
  #our $cn; $cn && ++$cn or $cn= 1; print "$cn\n";
 }
 $~= 'REPORT_FOOTER'; write;
}


# Parse a single C/C++ comment optionally preceded by whitespace.
# Returns the contents of the comment with leading/trailing spaces removed.
# This may be an empty string.
# Returns undef if no comment could be parsed.
sub parse_comment(\%) {
 my $p= shift;
 unless ($closing_c_remark) {
  $closing_c_remark= Lib::SimpleParser::create_trie(
   -delimiters => ['' => 0, '*/' => 1]
  );
  $closing_cpp_remark= Lib::SimpleParser::create_trie(
   -delimiters => ['' => 1, "\n" => 1]
  );
 }
 $p->skip_ws_eol;
 my $c;
 if ($p->try_parse_string('//')) {
  # C++ line remark.
  $p->skip_ws_eol;
  unless ($p->parse_until(-result => \$c, -trie => $closing_cpp_remark)) {
   $p->unget_string($c);
   $p->unget_string('//');
   return;
  }
 }
 elsif ($p->try_parse_string('/*')) {
  # C remark opening.
  $p->skip_ws_eol;
  unless ($p->parse_until(-result => \$c, -trie => $closing_c_remark)) {
   $p->unget_string($c);
   $p->unget_string('/*');
   return;
  }
 }
 else {return}
 $c =~ s/\s+$//s;
 $c;
}


sub read_ms_struct($$) {
 my($avi, $def)= @_;
 my(@s, $size);
 {
  my($p, $decl, $n, $t, $c, $cs, $cnt, $fsz);
  unless ($semicolon) {
   $semicolon= Lib::SimpleParser::create_trie(-delimiters => [';' => 0]);
  }
  $p= new Lib::SimpleParser;
  $p->init(-string => $def);
  for ($size= 0;;) {
   $p->skip_ws_eol;
   last if $p->try_parse_eof;
   $p->parse_until(
    -result => \$decl, -trie => $semicolon, -min_size => 1
   );
   $decl =~ s/[\s]+/ /gs; # Compress spaces.
   $decl =~ s/ \s+ ( [[:alpha:]_] \w* ) \s* (?: \[ (\d+) \] \s* )? $ //x;
   $n= $1; # Name.
   $cnt= $2 || 1; # Count.
   $n =~ s/ (?<= [a-z] ) (?= [A-Z]) /_/xg;
   $n= lc $n;
   # Map type.
   $t= ${{
    # Format: '<cname>' => [qw/<cnv> <sz> <needs_sep>/]
    # where
    # <cname>: 'C' name of data type.
    # <cnv>: Perl 'pack' conversion character.
    # <sz>: Size for data type in octets.
    # <needs_sep>: whether to insert separators when printing array.
    'DWORD' => [qw/V 4 y/]
    , 'char' => [qw/a 1 n/]
   }}{$decl};
   die "unsupported C type '$decl'" unless defined $t;
   for ($c= ''; $cs= parse_comment(%$p); $c.= $cs) {
    $c.= $cs eq '' ? "\n" : ' ' if $c gt '';
   }
   $c =~ s/ \n+ (?= \n ) | \s+ (?= [\s\n] | (?<= \n) \s+ ) //xgs;
   $size+= $fsz= $t->[1] * $cnt;
   push @s, {
    ctype => $decl, type_octets => $t->[1], offset => $size, octets => $fsz
    , name => $n, desc => $c, pack => $t->[0] . ($cnt > 1 ? $cnt : '')
    , count => $cnt, separate => $t->[2] ne 'n'
   };
  }
 }
 {
  my(@v, %r, $n);
  @v= unpack join('', map $_->{pack}, @s), $avi->read($size);
  %r= ('$' => {});
  foreach my $s (@s) {
   $n= delete $s->{name};
   # Field value.
   $r{$n}= join $s->{separate} ? ', ' : '', splice @v, 0, $s->{count};
   $r{'$'}->{$n}= $s; # Field info.
  }
  # Return value layout:
  # $r->{name}: Resulting value of the field.
  # $r->{'$'}->{name}->{ctype}: 'C' declaration type.
  # $r->{'$'}->{name}->{type_octets}: 'C' type single element storage size.
  # $r->{'$'}->{name}->{octets}: Field storage size in file in octets.
  # $r->{'$'}->{name}->{offset}: Octet offset for field.
  # $r->{'$'}->{name}->{desc}: Field description.
  # $r->{'$'}->{name}->{pack}: Perl 'pack' instruction for field value.
  # $r->{'$'}->{name}->{count}: Array size.
  # $r->{'$'}->{name}->{separate}: Whether array listing needs a separator.
  \%r;
 }
}


my $name= 'x:\\test\\test.divx.avi';
my($id, $group, @n, $n, $avi_header);
my $avi= Lib::RIFF->new($name);
$avi->enum; # 'RIFF'.
$avi->enter('AVI ');
do {
 while (($id, $group)= $avi->enum) {
  if ($group) {
   $id= $avi->enter;
   $n= join '->', @n;
   if (
    $id eq 'hdrl' && $n eq ''
    || $id eq 'strl' && $n eq 'hdrl'
    || $id eq 'odml' && $n eq 'hdrl'
   ) {
    push @n, $id;
   }
   else {
    # Group is not of interest.
    $avi->leave;
    $avi->skip;
   }
  }
  else {
   # Normal chunk.
   if ($id eq 'avih' && join('->', @n) eq 'hdrl') {
    $avi_header= read_ms_struct $avi, <<'.';
     DWORD TimeBetweenFrames;     /* Delay between frames in microseconds. */
     DWORD MaximumDataRate;       /* Data rate of the AVI data in bytes per second. */
     DWORD PaddingGranularity;    /* The multiple size of padding used in the data in bytes. When used, the value of this field is typically 2048. */
     DWORD Flags;                 /* Bit 4: AVI chunk contains an index subchunk (idx1). Bit 5: Use the index data to determine how to read the AVI data, rather than the physical order of the chunks with the RIFF file. Bit 8: AVI file is interleaved. Bit 16: AVI file is optimized for live video capture. Bit 17: AVI file contains copyrighted data. */
     DWORD TotalNumberOfFrames;   /* Indicates the total number of frames of video data stored in the movi subchunk within the first RIFF 'AVI' chunk. */
     DWORD NumberOfInitialFrames; /* Specifies the number of frames in the file before the actual AVI data. For non-interleaved data this value is 0. */
     DWORD NumberOfStreams;       /* Holds the number of data streams in the chunk. A file with an audio and video stream contains a value of 2 in this field, while an AVI file containing only video data has 1. In the current version of the RIFF format, one audio and one video stream are allowed. */
     DWORD SuggestedBufferSize;   /* Minimum size of the buffer to allocate for playback of the AVI data. For non-interleaved AVI data, this value is at least the size of the largest chunk in the file. For interleaved AVI files, this value should be the size of an entire AVI record. */
     DWORD Width;                 /* Width of video frame in pixels */
     DWORD Height;                /* Height of video frame in pixels */
     DWORD TimeScale;             /* Unit used to measure time in this chunk. It is used with DataRate to specify the time scale that the stream will use. For video streams, this value should be the frame rate and typically has a value of 30. For audio streams, this value is typically the audio sample rate. */
     DWORD DataRate;              /* Is divided by the TimeScale value to calculate the number of samples per second. */
     DWORD StartTime;             /* Starting time of the AVI data and is usually 0. */
     DWORD DataLength;            /* Size of the AVI chunk in the units specified by the TimeScale value. */
.
    $avi_header->{fps}
    = int(1 / ($avi_header->{time_between_frames} / 1e6) * 100) / 100
    ;
    $avi_header->{'$'}->{fps}= {desc => 'Frames per second.', count => 1};
    report 'AVI Header', %$avi_header;
   }
   elsif ($id eq 'strh' && join('->', @n) eq 'hdrl->strl') {
    my $stream_header= read_ms_struct $avi, <<'.';
     char  DataType[4];           /* 4-character identifier indicating the type of data the stream header refers to. Identifiers supported by the current version of the RIFF format are: vids for video data and auds for audio data. */
     char  DataHandler[4];        /* May contain a 4-character identifier specifying the preferred type of device to handle the data stream. */
     DWORD Flags;                 /* Set of bit flags use to indicate parameter settings related to the data. */
     DWORD Priority;              /* Set to 0. */
     DWORD InitialFrames;         /* How far the audio is placed ahead of the video in interleaved data in seconds. */
     DWORD TimeScale;             /* Unit used to measure time. */
     DWORD DataRate;              /* Data rate of playback. */
     DWORD StartTime;             /* Starting time of AVI data. */
     DWORD DataLength;            /* Size of AVI data chunk. */
     DWORD SuggestedBufferSize;   /* Minimum playback buffer size. */
     DWORD Quality;               /* Integer in the range of 0 to 10,000, indicating the quality factor used to encode the sample. */
     DWORD SampleSize;            /* Size of a single sample of data. If this value is 0, the sample varies in size and each sample is stored in a separate subchunk. If this value is non-zero, then all the samples are the same size and are stored in a single subchunk. */
     DWORD Unknown[2];
.
    report 'Stream Header', %$stream_header;
   }
   elsif ($id eq 'strf' && join('->', @n) eq 'hdrl->strl') {
    # StreamFormat
   }
   elsif ($id eq 'dmlh' && join('->', @n) eq 'hdrl->odml') {
    my $odml_extended_avi_header= read_ms_struct $avi, <<'.';
     DWORD dwTotalFrames; // Real total number of frames of video data stored in the movi subchunks within the combined RIFF 'AVI' chunks of the file.
     char Unknown[244];
.
    report 'ODML Extended AVI Header', %$odml_extended_avi_header;
   }
  }
  print Lib::RIFF::format_FOURCC($id), "\n";
 }
 pop @n;
} while $avi->leave;
$avi->close;
print "Done.\n";
exit;


# Reformat numeric string using '.' thousands separators.
sub fmt($) {
 join '.', split /(?= (?: .{3} )+ $ ) /x, shift;
}


sub advance(\$\$$) {
 my($buf, $off, $pat)= @_;
 my $pos= index $$buf, $pat, $$off;
 die "'$pat' not found in AVI file" if $pos < 0;
 $$off= $pos + length $pat;
}


sub avi_info($) {
 my $avi= shift;
 local(*IN);
 open IN, '<', $avi or die "Cannot open '$avi': $!";
 binmode IN or die;
 my($buf, $off, %r, @r);
 die "read error: $!" unless defined read(IN, $buf, 0x1000);
 close IN or die;
 $off= 0;
 advance($buf, $off, 'AVI ');
 die "bad AVI file" unless $off == 0x0c;
 advance($buf, $off, 'hdrl');
 advance($buf, $off, 'avih');
 die "Bad AVI header" unless unpack("x$off V", $buf) == 56;
 $off+= 0x4;
 @r= unpack "x$off V14", $buf;
 my @it= (
  qw(fdur avi_data_rate padding_multiple_size flags)
  , qw(frames preview_frames streams recommended_buf_size)
  , qw(width height time_scale data_rate starting_time)
  , qw(avi_chunk_size)
 );
 for (my $i= 0; $i < @r; ++$i) {
  $r{$it[$i]}= $r[$i];
 }
 $r{fps}= int(1 / ($r{fdur} / 1e6) * 100) / 100;
 delete $r{fdur};
 \%r;
}


=test
#my $fname= "K:\\Dokumente und Einstellungen\\All Users\\Dokumente\\Eigene Musik\\Musiksammlung\\Downloaded\\No Doubt - Don't Speak.divx.avi";
my $fname= "K:\\Dokumente und Einstellungen\\All Users\\Dokumente\\Eigene Videos\\Hannibal (2001, German).divx.avi";
my $i= avi_info($fname);
print "Output Resolution: $i->{width} x $i->{height}\n";
print "$i->{fps} frames/s\n";
exit;
    $_= 'Output file size: ' . fmt(-s $videofile) . " Bytes\n";
    $any= 1;
   }
   elsif (/^ Output \s Resolution .* \? /x) {
    my $i= avi_info($videofile);
    $_= "Output Resolution: $i->{width} x $i->{height}\n";
=cut
