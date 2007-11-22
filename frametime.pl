#!/usr/bin/perl

# GUI App for conversion between various frame/time based time stamps.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/frametime.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Tk;
use Tk::LabFrame;


my($fps, $usec, $hours, $minutes, $whs, $ms, $sf, $seconds, $frames);
my($fmts, $fmtf, $osz, $ofrq, $ofrqunit, $umen, $msec);
my($w, $f, $f2, $f3, $updating, $v);
$w= new MainWindow -title => 'Frame/Time Converter';


{
   package MutuallyDependentValues;
   # Instance data hash key prefix is 'myg9_';   

   
   sub new {
      my $self= shift;
      $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
      $self->{myg9_ctrl}= {};
      return $self;
   }
   
   
   # Adds a widget to the list of mutually dependent widgets.
   # Usage: $obj->add($name => $widget, options ...)
   #  $name is the widget access identifier.
   #  If the same name is used multiple times, multiple views will be
   #  created for the same bound value, sharing the same options (any
   #  options specified for the aliases will be ignored).
   #  As as special case, $widget can be undef, i. e. just $obj->($name).
   #  In this case, a hidden internal field will be created that may be
   #  used to store intermediate values for the calculation.
   # Options:
   # parse => sub {my $fields= shift}
   #  parse $_ and combine it with the current contents of the combined
   #  values from $fields, updating $fields by the retrieved values.
   #  $fields is a hash of the current values, indexed by access identifiers.
   #  Returns a boolean indicating success.
   #  On failure, any changes already done to $fields
   #  will be undone automatically (transactional behaviour).
   #  If this option is not specified, the widget will be display-only.
   # format => sub {my $fields= shift}
   #  return the formatted representation for this widget (derived from
   #  $fields) or return a error substitution string such as "??" or
   #  "(n/a)" etc
   #  The formatted representation will then replace the current (possibly
   #  unformatted) contents of the bound variable.
   # binding => '-variable'
   #  Specifies the widget's option for adding a variable binding.
   #  Initially defaults to '-textvariable'.
   #  A variable for the binding will automatically be created and bound.
   #  This option is irrelevant of $widget is undef.
   sub add {
      my($self, $name, $widget, %opt)= @_;
   }
}


sub oszunit {
   return
      defined($ofrqunit)
      && ${{
           'kHz' => 1e3
         , 'mHz' => 1e6
      }}{$ofrqunit}
      || 1
   ;
}


sub update {
   # Updates all values based on $usec and $fps.
   my($ts, $tfps);
   $ts= defined($usec)? $usec =~ /^\d+$/ ? $usec : 0 : 0;
   $tfps= defined($fps) ? $fps =~ /^\d+(?:\.\d*)?$/ ? $fps : 1 : 1;
   $frames= sprintf '%.3lf', $ts * $tfps / 1e6;
   $seconds= sprintf '%.3lf', $ts / 1e6;
   $msec= sprintf '%.3lf', $ts / 1e3;
   $osz= sprintf '%.3lf', $ts * ($ofrq || 0) * &oszunit / 1e6;
   $hours= int $ts / (60 * 60 * 1e6);
   $ts-= $hours * 60 * 60 * 1e6;
   $minutes= int $ts / (60 * 1e6);
   $ts-= $minutes * 60 * 1e6;
   $whs= int $ts / 1e6;
   $ts-= $whs * 1e6;
   $sf= $ts * $tfps / 1e6;
   $ms= int $ts / 1e3;
   $ts= sprintf '%u:%02u:%02u.', $hours, $minutes, $whs;
   $fmts= $ts . sprintf '%03u', $ms;
   $fmtf= $ts . sprintf '%02u', $sf;
   undef $updating;
};


sub floatv {
   my $v= shift;
   return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 6;
}


sub intv {
   my $v= shift;
   return $v =~ /^ \d* $/x && length($v) <= 2;
}


sub enqueue {
   my $action= shift;
   unless ($updating) {
      $updating= 1;
      $w->afterIdle(
         [
            sub {
               my $action= shift;
               &$action if $action;
               update;
            }
            , $action
         ]
      );
   }
}


sub chk {
   my($validator, $action, $v, undef, undef, undef, $a)= @_;
   # $validator: sub getting non-emtpy string to verify
   # $action: undef or sub to execute after non-empty valid string has been set
   # rest: arguments as passed to -vcmd
   if (defined($v) && $v gt '') {
      if (
         $v =~ /
            ^
            (?:
               \d
               | (?<! \. ) \.
               | : 
            )+
            $
         /x
         && &$validator($v)
      ) {
         enqueue $action if $a != -1 && !$updating;
      }
      else {
         return undef;
      }
   }
   return 1;
}


sub clear {
   $usec= 0;
   $fps= 25 unless $fps;
   unless ($ofrq) {
      $ofrq= 90;
      $umen->setOption('kHz');
   }
   update;
}


$v= new MutuallyDependentValues;
$f= $w->Frame->pack(
   my @fpk= (qw/-fill x -ipadx 2m/, my @spc= qw/-padx .5m -pady .5m/)
);
$f->Label(
   -text => 'Hint: Pressing the tabulator key completes editing a field.'
)->pack(my @lpk= (qw/-side left -ipadx .5m -ipady .5m/));
$f= $w->LabFrame(qw/-label Movie -labelside acrosstop/)->pack(@fpk);
my $p_nnflt= qr/ \d+ (?: \. \d* )? | \. \d+ /x;
$v->add(
   fps => $f->Entry(qw/-width 6 -justify right/)
      ->pack(my @epk= (qw/-side left/, @spc))
   , parse => sub {
      my $v= shift;
      return defined(($v{fps})= /^($p_nnflt)$/) && $v{fps} > 0;
   }
);
$f->Label(-text => 'frames per second')->pack(@lpk);
$f= $w->LabFrame(qw/-label HMMSS.ddd -labelside acrosstop/)->pack(@fpk);
$f2= $f->Frame->pack(my @pli= qw/-expand 1 -side left/);
my $p_pint= qr/ [1-9] \d* /x;
my $p_nnint= qr/ \d+ /x;
$v->add(
   hours => $f2->Entry(
      my @hours_args= (qw/-width 3 -justify right/)
   )->pack(@epk)
   , parse => sub {
      my $v= shift;
      if (defined(($v{hours})= /^($p_nnflt)$/) && $v{hours} < 24) {
         $f{usec}= $f{usec} - 60 * 60 * 1e6 * int($f{usec} / (60 * 60 * 1e6))
            + $f{hours} * 60 * 60 * 1e6
         ;
         return 1;
      }
      return undef;
   }
);
$f2->Label(-text => 'hours')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$v->add(
   minutes => $f2->Entry(
      my @minute_args= (qw/-width 3 -justify right/)
   )->pack(@epk)
   , parse => sub {
      my $v= shift;
      if (defined(($v{minutes})= /^($p_nnflt)$/) && $v{minutes} < 60) {
         $v{usec}= $v{usec} - int($v{usec} / 60 / 1e6) % 60 * 60 * 1e6
            + $v{minutes} * 60 * 1e6
         ;
         return 1;
      }
      return undef;
   }
);
$f2->Label(-text => 'minutes')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$v->add(
   whs => $f2->Entry(
      my @second_args= (qw/-width 3 -justify right/)
   )->pack(@epk)
   , parse => sub {
      my $v= shift;
      if (defined(($v{whs})= /^($p_nnflt)$/) && $v{whs} < 60) {
         $v{usec}= int($v{usec} / 60 / 1e6) * 60 * 1e6
            + $v{whs} * 1e6
            + $v{usec} % 1e6
         ;
         return 1;
      }
      return undef;
   }
);
$f2->Label(-text => 'seconds')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(
   -textvariable => \$ms, qw/-width 4 -validate key -justify right/
   , -vcmd => sub {
      chk sub {
         return shift =~ /^ \d{1,3} $/x;
      }
      , sub {
         $usec= int($usec / 1e6) * 1e6 + $ms * 1e3 + $usec % 1e3;
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => 'milliseconds')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(
   -textvariable => \$fmts, qw/-width 13 -validate focusout -justify right/
   , -vcmd => sub {
      chk sub {return shift =~ /^ [\d.:]+ $/x}
      , sub {
         if (
            my($h, $m, $s, $mss)= $fmts =~ /
               ^
               \s* (\d+) \s*
               [.:] \s* (\d+) \s*
               (?:
                  [.:] \s* (\d+) \s*
                  (?:
                     [.:] \s* (\d+) \s*
                  )?
               )?
               $
            /x
         ) {
            $usec= (($h * 60 + $m) * 60 + ($s || 0)) * 1e6 + ($mss || 0) * 1e3;
         }
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => '(formatted)')->pack(@lpk);
$f= $w->LabFrame(
   -label => 'SMPTE (HMMSS.ff)', qw/-labelside acrosstop/
)->pack(@fpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(@hours_args)->pack(@epk);
$f2->Label(-text => 'hours')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(@minute_args)->pack(@epk);
$f2->Label(-text => 'minutes')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(@second_args)->pack(@epk);
$f2->Label(-text => 'seconds')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(
   -textvariable => \$sf, qw/-width 4 -validate key -justify right/
   , -vcmd => sub {
      chk \&intv
      , sub {
         return unless defined($fps) && $fps > 0;
         $usec= int($usec / 1e6) * 1e6 + $sf * 1e6 / $fps;
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => 'frames')->pack(@lpk);
$f2= $f->Frame->pack(@pli);
$f2->Entry(
   -textvariable => \$fmtf, qw/-width 12 -validate focusout -justify right/
   , -vcmd => sub {
      chk sub {return shift =~ /^ [\d.:]+ $/x}
      , sub {
         if (
            defined($fps) && $fps > 0
            && (
               my($h, $m, $s, $fss)= $fmtf =~ /
                  ^
                  \s* (\d+) \s*
                  [.:] \s* (\d+) \s*
                  (?:
                     [.:] \s* (\d+) \s*
                     (?:
                        [.:] \s* (\d+) \s*
                     )?
                  )?
                  $
               /x
            )
         ) {
            $usec= (($h * 60 + $m) * 60 + ($s || 0)) * 1e6
               + ($fss || 0) * 1e6 / $fps
            ;
         }
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => '(formatted)')->pack(@lpk);
$f= $w->LabFrame(qw/-label Absolute -labelside acrosstop/)->pack(@fpk);
$f2= $f->Frame->pack(@fpk);
$f2->Entry(
   -textvariable => \$seconds, qw/-width 10 -validate focusout -justify right/
   , -vcmd => sub {
      chk
      sub {
         my $v= shift;
         return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 10;
      }
      , sub {
         $usec= $seconds * 1e6;
      }, @_
   }
)->pack(@epk);
$f2->Label(-text => 'seconds')->pack(@lpk);
$f2= $f->Frame->pack(@fpk);
$f2->Entry(
   -textvariable => \$frames, qw/-width 10 -validate focusout -justify right/
   , -vcmd => sub {
      chk
      sub {
         my $v= shift;
         return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 10;
      }
      , sub {
         return unless defined($fps) && $fps > 0;
         $usec= int $frames * 1e6 / $fps;
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => 'frames')->pack(@lpk);
$f2= $f->Frame->pack(@fpk);
$f2->Entry(
   -textvariable => \$msec, qw/-width 10 -validate focusout -justify right/
   , -vcmd => sub {
      chk
      sub {
         my $v= shift;
         return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 10;
      }
      , sub {
         $usec= $msec * 1e3 + $usec % 1e3;
      }
      , @_
   }
)->pack(@epk);
$f2->Label(-text => 'milliseconds')->pack(@lpk);
$f2= $f->Frame->pack(@fpk);
$f3= $f2->Frame->pack(@pli, qw/-fill x/);
$f3->Entry(
   -textvariable => \$osz, qw/-width 14 -validate focusout -justify right/
   , -vcmd => sub {
      chk
      sub {
         my $v= shift;
         return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 14;
      }
      , sub {
         if (defined($ofrq) && $ofrq > 0) {
            $usec= int $osz * 1e6 / ($ofrq * oszunit);
         }
      }
      , @_
   }
)->pack(@epk);
$f3->Label(-text => 'cycles')->pack(@lpk);
$f3= $f2->Frame->pack(@pli);
$f3->Label(-text => 'for a')->pack(@lpk);
$f3= $f2->Frame->pack(@pli);
$f3->Entry(
   -textvariable => \$ofrq, qw/-width 10 -validate key -justify right/
   , -vcmd => sub {
      chk
      sub {
         my $v= shift;
         return $v =~ /^ \d* (?: \. \d* )? $/x && length($v) <= 10;
      }
      , undef
      , @_
   }
)->pack(@epk);
$umen= $f3->Optionmenu(
   -options => [qw/Hz kHz mHz/]
   , -variable => \$ofrqunit
   , -command => sub{enqueue}
)->pack(qw/-anchor w -expand y -padx .2c/);
$f3= $f2->Frame->pack(@pli);
$f3->Label(-text => 'oscillator')->pack(@lpk);
$f2= $f->Frame->pack(@fpk);
$f2->Entry(
   -textvariable => \$usec, qw/-width 14 -validate key -justify right/
   , -vcmd => sub {
      chk
      sub {return shift =~ /^ \d{1,14} $/x}
      , undef, @_
   }
)->pack(@epk);
$f2->Label(-text => 'microseconds')->pack(@lpk);
$f= $w->Frame->pack(@fpk, qw/-expand 1/);
$f->Label(-text => '(C) 2004 Guenther Brunthaler')->pack(
   @lpk, qw/-expand 1/
);
$w->Button(
   qw/-text Clear/, -command => \&clear
)->pack(qw/-side left/, @spc);
$w->Button(
   qw/-text Quit/, -command => [$w => 'destroy']
)->pack(qw/-side right/, @spc);
clear;
MainLoop;
