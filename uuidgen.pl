#! /usr/bin/perl
# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 1034 $
# $Date: 2007-11-18T05:27:18.961486Z $
# $Author: root $
# $State$
# $xsa1$


# $xsa2={8530E5A0-F2CD-11D4-97BF-0050BACC8FE1}:title=UUID-Generator$
# UUID/GUID definition generator for copying/pasting into source files.
# $xsa2:description$
# This tool generates unique names in form of UUIDs ([U]niversally [U]nique
# [ID]entifier) or GUIDs ([G]lobally [U]nique [ID]entifier, the Microsoft
# version of an UUID) and creates source-text fragments based on those
# names.
#
# Different styles of source code fragments can be selected for generation,
# and the resulting fragment will be written into a window.
# From there it can be copied into your own source text using copy/paste.
# $xsa2:end$


use FindBin;
use Tk;
use Tk::Font;
use Tk::LabFrame;
use Getopt::Long;
use strict;


eval << '.' if $^O eq 'MSWin32';
{
   use Win32::API;
   package UUID;


   use constant RPC_S_OK => 0;
   # A UUID that is valid only on this computer has been allocated.
   # The UUID is guaranteed to be unique to this computer only.
   use constant RPC_S_UUID_LOCAL_ONLY => 1824;
   # No network address is available to use to construct a universal
   # unique identifier (UUID).
   # Cannot get Ethernet or token-ring hardware address for this computer.
   use constant RPC_S_UUID_NO_ADDRESS => 1739;


   sub new {
      my($class)= shift;
      my $self= {
         buffer => pack('a16')
      };
      unless (
         $self->{api}= new Win32::API(
            'rpcrt4', 'UuidCreateSequential', ['P'], 'N'
         )
      ) {
         # pre W2K method.
         $self->{preW2K}= 1;
         {
            my $api= new Win32::API('ole32', 'CoInitialize', ['N'], 'N');
            die "Cannot access OLE2 API" unless $api;
            die "Cannot initialize OLE2" if $api->Call(0);
         }
         $self->{api}= new Win32::API('ole32', 'CoCreateGuid', ['P'], 'N');
         die "Cannot get OLE2 support for UUID generation" unless $self->{api};
      }
      if (
         $self->{rapi}= new Win32::API('rpcrt4', 'UuidCreate', ['P'], 'N')
      ) {
         my $r= $self->{rapi}->Call($self->{buffer});
         if (
            $r != RPC_S_UUID_LOCAL_ONLY && $r != RPC_S_OK
            || unpack('x8B2', $self->{buffer}) ne '10' # variant 'DCE'
            || unpack('x7B4', $self->{buffer}) ne '0100' # randomly generated
         ) {
            undef $self->{rapi};
         }
      }
      bless $self, ref $class || $class;
   }


   # Returns an unformatted UUID.
   # Argument is optional.
   # If specified, must be a reference to a hash:
   # [IN] $arg->{want_random}: Generate random- rather than time-based UUID
   # [OUT] $arg->{is_random}: true if returned UUID is random-based
   # [OUT] $arg->{is_local}: true if returned UUID is only locally unique
   # [OUT] $arg->{domain}: textual domain classification of returned UUID
   # The method returns the new UUID as a list consisting of:
   # 1 long (32-bit), 2 shorts (16-bit), 8 octets
   sub create {
      my($self, $retflags)= @_;
      $retflags= {} unless ref $retflags eq 'HASH';
      my $api= $retflags->{want_random} && defined($self->{rapi})
      ? $self->{rapi}
      : $self->{api}
      ;
      {
         my $r= $api->Call($self->{buffer});
         undef $retflags->{is_random};
         undef $retflags->{is_local};
         if ($r == RPC_S_UUID_LOCAL_ONLY) {
            $retflags->{is_local}= 1;
         }
         elsif ($r == RPC_S_UUID_NO_ADDRESS) {
            if (defined($self->{rapi}) && $api != $self->{rapi}) {
               $api= $self->{rapi};
               redo;
            }
            die "No network address is available to use to construct a"
               . " universal unique identifier (UUID).\n"
               . "Cannot get Ethernet or token-ring hardware address for"
               .  " this computer"
            ;
         }
         elsif ($r != RPC_S_OK) {
            die "UUID creation failed with unexpected return code";
         }
      }
      if (unpack('x8B2', $self->{buffer}) ne '10') {
         die "unsupported UUID variant returned by generator"
      }
      my $ver= unpack 'x7B4', $self->{buffer};
      if ($ver eq '0100') {
         $retflags->{is_random}= 1;
         $retflags->{domain}= 'randomly generated';
      }
      else {
         $retflags->{domain}= ${{
            '0001' => 'time based'
            , '0010' => 'POSIX security'
            , '0011' => 'name based'
         }}{$ver};
         unless (defined $retflags->{domain}) {
            $retflags->{domain}= "unknown domain";
         }
      }
      if ($retflags->{is_local}) {
         $retflags->{domain}.= ', locally unique on this machine only';
      }
      elsif ($retflags->{is_random}) {
         $retflags->{domain}.= ', most likely unique';
      }
      else {
         $retflags->{domain}.= ', guaranteed universal uniqueness';
      }
      unpack 'LSSC8', $self->{buffer};
   }


   sub DESTROY {
      if (shift->{preW2K}) {
         my $api= new Win32::API('ole32', 'CoUninitialize', [], 'V');
         die unless $api;
         die if $api->Call();
      }
   }
}
.


eval << '.' if $^O eq 'linux';
{
   package UUID;


   sub new {
      my $class= shift;
      bless {}, ref $class || $class;
   }


   # Returns an unformatted UUID.
   # Argument is optional.
   # If specified, must be a reference to a hash:
   # [IN] $arg->{want_random}: Generate random- rather than time-based UUID
   # [OUT] $arg->{is_random}: true if returned UUID is random-based
   # [OUT] $arg->{is_local}: true if returned UUID is only locally unique
   # [OUT] $arg->{domain}: textual domain classification of returned UUID
   # The method returns the new UUID as a list consisting of:
   # 1 long (32-bit), 2 shorts (16-bit), 8 octets
   sub create {
      my($self, $retflags)= @_;
      $retflags= {} unless ref $retflags eq 'HASH';
      local *GEN;
      open GEN, 'uuidgen -' . ($retflags->{want_random} ? 'r' : 't') . " |"
      or die "Could not obtain UUID from 'uuidgen'";
      $self->{buffer}= <GEN>;
      close GEN or die;
      undef $retflags->{is_random};
      undef $retflags->{is_local};
      {
         my($L, $s1, $s2, $s3, @b)= $self->{buffer} =~ /
            ^ ([[:xdigit:]]{8}) - ([[:xdigit:]]{4})
            - ([[:xdigit:]]{4}) - ([[:xdigit:]]{4})
            -
               ([[:xdigit:]]{2}) ([[:xdigit:]]{2}) ([[:xdigit:]]{2})
               ([[:xdigit:]]{2}) ([[:xdigit:]]{2}) ([[:xdigit:]]{2})
            $
         /x;
         die unless defined $b[5];
         $self->{buffer}= pack 'LSSnC6', map hex, $L, $s1, $s2, $s3, @b;
      }
      if (unpack('x8B2', $self->{buffer}) ne '10') {
         die "unsupported UUID variant returned by generator"
      }
      my $ver= unpack 'x7B4', $self->{buffer};
      if ($ver eq '0100') {
         $retflags->{is_random}= 1;
         $retflags->{domain}= 'randomly generated';
      }
      else {
         $retflags->{domain}= ${{
            '0001' => 'time based'
            , '0010' => 'POSIX security'
            , '0011' => 'name based'
         }}{$ver};
         unless (defined $retflags->{domain}) {
            $retflags->{domain}= "unknown domain";
         }
      }
      if ($retflags->{is_local}) {
         $retflags->{domain}.= ', locally unique on this machine only';
      }
      elsif ($retflags->{is_random}) {
         $retflags->{domain}.= ', most likely unique';
      }
      else {
         $retflags->{domain}.= ', guaranteed universal uniqueness';
      }
      unpack 'LSSC8', $self->{buffer};
   }
}
.


# Return HEX-formatted UUID.
# Takes same arguments as create-method.
sub create_GUID {
   my($uugen, $retflags)= @_;
   sprintf('%08lX%04lX%04lX' . ('%02lX' x 8), $uugen->create($retflags));
}


sub GUID2Str($) {
   my($s)= @_;
   return undef unless defined $s;
   die "Invalid GUID hex encoding '$s'!" unless (
      $s =~ s<
         ^
         ([0-9A-F]{8})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{12})
         $
      ><{$1-$2-$3-$4-$5}>ox
   );
   $s;
}


eval << '.' if $^O =~ /^MSWin/;
   sub get_settings_file {
      my $n= shift;
      my $sfp= new Win32::API(
         'shell32', 'SHGetFolderPathA', [qw/N N N N P/], 'N'
      );
      die unless $sfp;
      use constant CSIDL_APPDATA => 0x1a;
      use constant CSIDL_FLAG_CREATE => 0x8000;
      use constant SHGFP_TYPE_CURRENT => 0;
      use constant MAX_PATH => 260;
      use constant S_OK => 0;
      my $buf= pack 'x' . (MAX_PATH + 1);
      if (
         $sfp->Call(
            0, CSIDL_APPDATA | CSIDL_FLAG_CREATE, 0, SHGFP_TYPE_CURRENT, $buf
         )
         != S_OK
      ) {
         die "failed locating user's application data directory";
      }
      unpack('Z*', $buf) . "\\$n.ini";
   }
.


eval << '.' if $^O eq 'linux';
   sub get_settings_file {
      my $n= shift;
      return "$ENV{HOME}/.$n";
   }
.


sub settext {
   my($widget, $data)= @_;
   $data= '' unless defined $data;
   while (chomp($data)) {}
   $widget->delete('1.0', 'end');
   $widget->insert('end', $data . "\n");
}


sub indent {
   my($g, $times)= @_;
   $times*= $g->{indent_repeat} if $g->{indent_repeat} > 0;
   $times+= $g->{indent_base} if $g->{indent_base} > 0;
   $g->{indent} x $times;
}


sub remark {
   my($g, $line)= @_;
   if ($g->{rmkstyle} eq 'C') {
      '/* ' . $line . ' */';
   }
   elsif ($g->{rmkstyle} eq 'C++') {
      '// ' . $line;
   }
   else {
      '';
   }
}


sub get_guid {
   my($g)= @_;
   create_GUID $g->{uuid}, $g->{uuidflags};
}


sub cv2b35 {
   use Math::BigInt;
   my($v, $r, $t);
   my $a= join '', '0' .. '9', 'A' .. 'N', 'P' .. 'Z';
   my $digs= 25; # ceil(128 / log2(length $a))
   $v= new Math::BigInt 0;
   foreach (unpack 'C*', pack 'H*', shift) {
      $v= $v * 256 + $_;
   }
   $r= '';
   while (--$digs >= 0) {
      ($v, $t)= $v->bdiv(length $a);
      $r= substr($a, $t, 1) . $r;
      $v= new Math::BigInt $v;
   }
   $r;
}


sub cvfromb35 {
   use Math::BigInt;
   my($v, $r, $t);
   my $a= join '', '0' .. '9', 'A' .. 'N', 'P' .. 'Z';
   my $base= new Math::BigInt 256;
   my $digs= 16; # ceil(128 / log2($base))
   $v= new Math::BigInt 0;
   foreach (split //, uc shift) {
      $v= $v * length($a) + index($a, $_);
   }
   $r= '';
   while (--$digs >= 0) {
      ($v, $t)= $v->bdiv($base);
      $r= pack('C', $t) . $r;
      $v= new Math::BigInt $v;
   }
   uc unpack 'H*', $r;
}


sub user_guid {
   my($g)= @_;
   $g->{user_guid}= $g->{ow}->get(qw/ 1.0 end/);
   unless (
      $g->{user_guid} =~ s/
         ^.*?
         ([0-9A-F]{8}).*?
         ([0-9A-F]{4}).*?
         ([0-9A-F]{4}).*?
         ([0-9A-F]{4}).*?
         ([0-9A-F]{12}).*
         $
      /\U$1$2$3$4$5/ixs
   ) {
      if (
         $g->{user_guid} =~ /(?<![0-9A-NP-Z])([0-9A-NP-Z]{25})(?![0-9A-NP-Z])/i
      ) {
         $g->{user_guid}= cvfromb35($1);
      }
      else {
         $g->{user_guid}= '0' x 32;
      }
   }
   $g->{user_guid};
}


sub JoinPattern {
   (join "\n", @_) . "\n";
}


sub ExpandPattern {
   my($g, $pat)= @_;
   my($i, $c, %s, $u);
   $pat= $g->{userpat} unless defined $pat;
   $u= &{$g->{guid_method} eq 'G' ? \&get_guid : \&user_guid}($g);
   if ($pat =~ /\$(?!z)/i) {
      for ($i= 0; $i < 16; ++$i) {
         $s{lc $c}= lc($s{$c= chr(ord('A') + $i)}= substr $u, 2 * $i, 2);
      }
   }
   if ($pat =~ /\$z/i) {
      $u= cv2b35($u);
      for ($i= 0; $i < 25; ++$i) {
         $s{'z' . lc $c}= lc(
            $s{'Z' . ($c= chr ord('A') + $i)}= substr $u, $i, 1
         );
      }
      $s{'ZZ'}= '$';
      $s{'zzb'}= $g->{indent} x $g->{indent_base};
      $s{'zzi'}= $g->{indent} x $g->{indent_repeat};
      if ($g->{rmkstyle} eq 'C') {
         $s{'zzo'}= '/* ';
         $s{'zzc'}= ' */';
      }
      elsif ($g->{rmkstyle} eq 'C++') {
         $s{'zzo'}= '// ';
         $s{'zzc'}= '';
      }
      else {
         $s{'zzo'}= '';
         $s{'zzc'}= '';
      }
      $s{'zzs'}= $g->{storage_class};
      $s{'zz1'}= $g->{name};
      $s{'zz2'}= $g->{symbol};
   }
   $pat =~ s/\$(z[a-y]|zz[biocs12]|Z[A-Z]|[a-pA-P])/$s{$1}/gs;
   return $pat;
}


sub ApplyPattern {
   my($g, $pat)= @_;
   settext $g->{ow}, ExpandPattern $g, $pat;
}


my(%g);
$g{uuidflags}= {want_random => 0};
$g{rmkstyle}= 'C++';
$g{indent}= ' ';
$g{indent_base}= 0;
$g{indent_repeat}= 1;
$g{uuid}= new UUID;
$g{guid_method}= 'G';
if (@ARGV) {
   Getopt::Long::Configure("bundling");
   my $upper;
   $g{userpat}= '$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy';
   exit unless GetOptions(
      'h|?|help' => sub {
         print
              "$0 [ <options> <number_of_uuids> ]\n"
            , "If no arguments are given, the GUI will be launched.\n"
            , "options:\n"
            , "--upper, --upper-case, -u: Use upper case characters\n"
            , "--hex: Use hexadecimal rather than base-35 encoding\n"
            , "--guid, -g: Microsoft-style GUID\n"
         ;
         die "stopped";
      }, 'upper|upper-case|u' => \$upper
      , 'hex' => sub {$g{userpat}= '$a$b$c$d-$e$f-$g$h-$i$j-$k$l$m$n$o$p'}
      , 'guid|g' => sub {$g{userpat}= '{$a$b$c$d-$e$f-$g$h-$i$j-$k$l$m$n$o$p}'}
   );
   my $n= shift;
   die unless $n =~ /^\d+$/;
   $g{userpat}= uc $g{userpat} if $upper;
   while ($n--) {
      print ExpandPattern(\%g), "\n";
   }
}
else {
   my($wnd, $ow, $f, @p1, %plib);
   my @plib= (
      Registry_Button => JoinPattern('{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}'),
      Jet_Button => JoinPattern('{guid {$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}}'),
      Hex_Button => JoinPattern('$A$B$C$D$E$F$G$H$I$J$K$L$M$N$O$P'),
      '#ifndef_Button' => JoinPattern(
         '$zzb#ifndef HEADER_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_INCLUDED',
         '$zzb$zzi#define HEADER_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_INCLUDED',
         '',
         '$zzb#endif $zzo!HEADER_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_INCLUDED$zzc'
      ),
      Packed_Declaration => JoinPattern(
         '$zz1_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY',
         '',
         '$zzb$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzb$zzs char const *$zz1= "$zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy";'
      ),
      Packed_Button => JoinPattern(
         '_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY',
         '',
         '_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy',
         '',
         '$zz1_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY',
         '',
         '"$zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy"'
      ),
      UUID_CONST_Button => JoinPattern(
         '$zzb$zzs UUID_CONST(',
         '$zzb$zzi$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzb$zzi$zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy',
         '$zzb$zzi, 0x$a$b$c$d, 0x$e$f, 0x$g$h',
         '$zzb$zzi, 0x$i, 0x$j, 0x$k, 0x$l, 0x$m, 0x$n, 0x$o, 0x$p',
         '$zzb);'
      ),
      UUID_CONST_Declaration => JoinPattern(
         '$zzb$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzb$zzs UUID const $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy;',
         '',
         '$zzb$zzs UUID_CONST(',
         '$zzb$zzi$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzb$zzi$zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy',
         '$zzb$zzi, 0x$a$b$c$d, 0x$e$f, 0x$g$h',
         '$zzb$zzi, 0x$i, 0x$j, 0x$k, 0x$l, 0x$m, 0x$n, 0x$o, 0x$p',
         '$zzb);'
      ),
      NS_Declaration => JoinPattern(
         '$zzbusing namespace $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy;',
         '',
         '$zzbusing $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy::$zz2;',
         '',
         '$zzb$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzbnamespace $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy {',
         '',
         '} $zzonamespace $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy$zzc'
      ),
      NS_Button => JoinPattern(
         '$zzbnamespace $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy {',
         '',
         '} $zzonamespace $zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy$zzc'
      ),
      Learned_Button => undef,
      Default => JoinPattern('$zz1_$A$B$C$D_$E$F_$G$H_$I$J_$K$L$M$N$O$P'),
      DEFINE_GUID_Menu => JoinPattern(
         '$zzbDEFINE_GUID(',
         '$zzb$zzi$zzo{$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}$zzc',
         '$zzb$zzi$zz1_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy,',
         '$zzb$zzi0x$a$b$c$dL, 0x$e$f, 0x$g$h,',
         '$zzb$zzi0x$i, 0x$j, 0x$k, 0x$l, 0x$m, 0x$n, 0x$o, 0x$p',
         '$zzb);'
      ),
      FEATURE_Menu => JoinPattern(
         '$zzb#define FEATURE_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_ENABLED',
         '',
         '$zzb#ifdef FEATURE_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_ENABLED',
         '$zzb#endif $zzo!FEATURE_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY_ENABLED$zzc'
      ),
      Example_Menu => JoinPattern(
         'Upper Hex: {$A$B$C$D-$E$F-$G$H-$I$J-$K$L$M$N$O$P}',
         'Lower Hex: {$a$b$c$d-$e$f-$g$h-$i$j-$k$l$m$n$o$p}',
         'Upper ID: Name_$A$B$C$D_$E$F_$G$H_$I$J_$K$L$M$N$O$P',
         'Lower ID: name_$a$b$c$d_$e$f_$g$h_$i$j_$k$l$m$n$o$p',
         'Upper Packed: Name_$ZA$ZB$ZC$ZD$ZE$ZF$ZG$ZH$ZI$ZJ$ZK$ZL$ZM$ZN$ZO$ZP$ZQ$ZR$ZS$ZT$ZU$ZV$ZW$ZX$ZY',
         'Lower Packed: name_$za$zb$zc$zd$ze$zf$zg$zh$zi$zj$zk$zl$zm$zn$zo$zp$zq$zr$zs$zt$zu$zv$zw$zx$zy',
         'Struct Data 1: 0x$a$b$c$d, 0x$e$f, 0x$g$h',
         'Struct Data 2: 0x$i, 0x$j, 0x$k, 0x$l, 0x$m, 0x$n, 0x$o, 0x$p',
         'Storage Class: $zzs',
         'Primary symbol name (\'name\'): $zz1',
         'Secondary symbol name (\'symbol\'): $zz2',
         'Dollar Sign: $ZZ',
         'Base Indent: $ZZ$zzb^',
         'Indent by 1: $ZZ$zzb$zzi^',
         'Indent by 2: $ZZ$zzb$zzi$zzi^',
         'Remark: $zzoThis is a comment.$zzc'
      )
   );
   %plib= @plib;
   for (my $i= @plib + 1; ($i-= 2) >= 1;) {
      splice @plib, $i, 1;
   }
   $g{settingsfile}= get_settings_file('uuidgen_5iqkdlgvg9fbdzwyj9wucn5za');
   $wnd= MainWindow->new(-title => 'UUID Creator');
   $wnd->Label(
      -text => 'UUID Creator', -font => $wnd->Font(-size => 16)
   )->pack;
   $f= $wnd->Frame->pack(qw/-fill x -pady 5/);
   @p1= qw/-side left -padx 5/;
   $f->Label(-text => 'UUID:')->pack(@p1);
   $g{ow}= $ow= $f->Scrolled(
      qw/Text -scrollbars e -width 77 -height 10 -wrap word/
   )->pack(@p1);
   $f= $wnd->Frame->pack(qw/-fill x -pady 5/);
   {
      my($f2, $f3);
      $f2= $f->LabFrame(
         -label => 'Remark style', qw/-labelside acrosstop/
      )->pack(qw/-side left -fill y/);
      foreach ('C', 'C++') {
         $f2->Radiobutton(
            -text => $_,
            -variable => \$g{rmkstyle},
            -value => $_,
            -command => sub {settext $ow}
         )->pack(qw/-anchor w/);
      }
      $f2= $f->LabFrame(
         -label => 'Indentation', qw/-labelside acrosstop/
      )->pack(qw/-side left -fill y/);
      {
         my $f3= $f2->Frame->pack(qw/-side left -anchor nw -padx .2c/);
         foreach (
            {qw/-row 0 -prompt Initial -max 0/, -var => \$g{indent_base}},
            {qw/-row 1 -prompt Indent -max 1/, -var => \$g{indent_repeat}}
         ) {
            $f3->Label(
               -text => $_->{'-prompt'} . ':'
            )->grid(qw/-sticky e -ipady .05c -column 0/, -row => $_->{'-row'});
            $f3->Entry(
               -textvariable => $_->{'-var'}, qw/-width 2 -validate key/,
               -vcmd => do {
                  my $f= 'validator' . $_->{'-row'};
                  eval qq(
                     sub $f {
                        my(\$newval)= \@_;
                        settext \$ow;
                        \$newval eq '' || \$newval >= $_->{'-max'};
                     }
                  );
                  \&$f;
               }
            )->grid(qw/-sticky w -column 1/, -row => $_->{'-row'});
         }
      }
      foreach (['Tabs', "\t"], ['Spaces', " "]) {
         $f2->Radiobutton(
            -text => $_->[0],
            -variable => \$g{indent},
            -value => $_->[1],
            -command => sub {settext $ow}
         )->pack(qw/-anchor w/);
      }
      $f2= $f->LabFrame(
         -label => 'Storage Class', qw/-labelside acrosstop/
      )->pack(qw/-side left -fill y/);
      $f2->Optionmenu(
         -options => [qw/static extern/],
         -variable => \$g{storage_class},
      )->pack(qw/-anchor w -expand y -padx .2c/);
      $f2->Checkbutton(
         -text => "Declaration", -variable => \$g{declaration}
      )->pack(qw/-anchor w -expand y -padx .2c/);
      $f2= $f->LabFrame(
         -label => 'UUID Source', qw/-labelside acrosstop/
      )->pack(qw/-side left -fill y/);
      $f2->Radiobutton(
         -text => 'Generator',
         -variable => \$g{guid_method},
         -value => 'G',
      )->pack(qw/-anchor w/);
      $f2->Radiobutton(
         -text => 'Text above',
         -variable => \$g{guid_method},
         -value => 'U',
      )->pack(qw/-anchor w/);
      $f2= $f->LabFrame(
         -label => 'User Pattern', qw/-labelside acrosstop/
      )->pack(qw/-side left -fill y/);
      $f2->Optionmenu(
         -options => [
            qw/Learn! Default/
            , map {s/(.+)_Menu$/$1/; $_} grep {/_Menu$/} @plib
         ],
         -variable => \$g{learn_opt},
         -command => sub {
            if ($g{learn_opt} eq 'Learn!') {
               my $old_pat= $g{userpat};
               $g{userpat}= $ow->get(qw/ 1.0 end/);
               settext $ow, $old_pat;
            }
            elsif ($g{learn_opt} eq 'Default') {
               settext $ow, $g{userpat}= $g{dfltpat};
            }
            else {
               if (
                  $g{declaration}
                  && exists $plib{$g{learn_opt} . "_Declaration"}
               ) {
                  settext $ow
                     , $g{userpat}= $plib{$g{learn_opt} . "_Declaration"}
                  ;
               }
               else {
                  settext $ow, $g{userpat}= $plib{$g{learn_opt} . "_Menu"};
               }
            }
         }
      )->pack(qw/-anchor w -expand y -padx .2c/);
      {
         my $f3= $f2->Frame()->pack(qw/-anchor w -expand y -padx .2c/);
         my $r= 1;
         foreach (
            ['Symbol', 'name', \$g{name}]
            , ['Subsym', 'symbol', \$g{symbol}]
         ) {
            $f3->Button(
               -text => $_->[0] . ':'
               , -command => [
                  sub {
                     my($d, $s)= @_;
                     $$d= $s;
                  }
                  , $_->[2], $_->[1]
               ]
            )->grid(qw/-sticky ew -column 1/, -row => $r);
            $f3->Label(-text => ':')->grid(
               qw/-sticky e -column 2/, -row => $r
            );
            ${$_->[2]}= $_->[1];
            $f3->Entry(
               -textvariable => $_->[2]
               , qw/-width 10/
            )->grid(qw/-sticky w -column 3/, -row => $r);
            ++$r;
         }
      }
   }
   $f= $wnd->Frame->pack(qw/-fill x -pady 5/);
   $g{learn_opt}= 'Example';
   $g{dfltpat}= $g{userpat}= $plib{Default};
   foreach (@plib) {
      next unless s/(.+)_Button$/$1/;
      $f->Button(
         -text => $_,
         -command => [
            sub {
               my $f= shift;
               if ($g{declaration} && exists $plib{$f . "_Declaration"}) {
                  ApplyPattern \%g, $plib{$f . "_Declaration"};
               }
               else {
                  ApplyPattern \%g, $plib{$f . "_Button"};
               }
            },
            $1
         ]
      )->pack(@p1);
   }
   $f->Button(qw/-text Quit/, -command => [$wnd => 'destroy'])->pack(
      @p1, qw/-side right -padx 5/
   );
   $f= $wnd->Menu(qw/-type menubar/);
   $wnd->configure(-menu => $f);
   {
      my $m;
      $m= $f->cascade(-label => 'File', -tearoff => 0);
      $m->command(-label => 'Exit', -command => [$wnd => 'destroy']);
      $m= $f->cascade(-label => 'Generator');
      $m->radiobutton(
         -label => '~Time based unique'
         , -value => 0, -variable => \$g{uuidflags}->{want_random}
      );
      $m->radiobutton(
         -label => '~Randomly generated'
         , -value => 1, -variable => \$g{uuidflags}->{want_random}
      );
      $m->command(
         -label => '~Name based', -state => 'disabled' # NYI
      );
   }
   MainLoop;
}
