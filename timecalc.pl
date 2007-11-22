#!/usr/bin/perl
# Time UPN calculator

# written by Guenther Brunthaler in 2003
# $Id: /trunk/Org/SysAdmin/Crossplatform/bin/timecalc.pl 2647 2006-08-26T07:45:40.216781Z gb  $


$usage= <<"END";
$0 is a command line UPN time calculator

Usage: $0 <upn_expr>

where <upn_expr>
is a list of time values and operators.

The argument list is processed from left to right as follows:
When a time value is encountered, it is converted into seconds an pushed
onto the calculator stack.

When an operator is encountered, it pops as many arguments off the stack,
performs its operation, and finally pushes its results back onto the stack.

After all arguments have been processed, all time values left on the stack
are printed (typically just a single result value).

A time value is the concatenation of date and time items, where each item
is optional but at least one item must be specified.

The following date/time items are supported:

<number> (y | year | years)
<number> (m | month | months)
<number> (w | week | weeks)
<number> (d | day | days)
<number> (h | hour | hours)
<number> (n | minute | minutes)
<number> (s | second | seconds)

The items do not need to be separated from each other, but may be separated
by whitespace and/or commas. (If whitespace is used, then the whole time value
must be enclosed within double quotes.)

The years-, months- and days-part may also be specified using
one of the following alternative variants:

"number-number" means years and months
"number-number-number" means years, months and days.

In those alternative variants, optional whitespace is allowed between
the numbers and the dashes. (If whitespace is used, then the whole time value
must be enclosed within double quotes.)

The hours-, minutes- and seconds-part may also be specified using
one of the following alternative variants:

"number" alone is an 'hours' value
"number:number" means hours and minutes
"number:number:number" means hours, minutes and seconds.

In those alternative variants, the numbers can also be separated by
whitespace, a comma or a dot. (If whitespace is used, then the whole time value
must be enclosed within double quotes.)

Some examples for time values:

"5" is 5 hours
"13.30" means 13:30 hours
"13:22.33" means 13:22 hours and 33 seconds
"13h,22" means 13 hours and 22 minutes
"1 year, 3 weeks, 4 n" means 1 year, 21 days and 4 minutes
"3 days, 5 1s" means 3 days, 5 hours and 1 second
"1998y3m30d5:2s" means 1998 years, 3 months, 30 days, 5 hours and 2 seconds
"6m30d7:3" means 6 months, 30 days, 7 hours and 3 minutes
"1998-12-24 16:3" means 1998 years, 11 months, 23 days, 16 hours and 3 minutes
"1998-1-1 14:2" means 1998 years, 14 hours and 2 minutes
"1998-2-2 2n" means 1998 years, 1 month, 1 day and 2 minutes

Note that the calculator does not do real date arithmetic; it just converts
all items into seconds using average month and year lengths.

The following operators are supported:

"<val1> <val2> +" pushes result of <val1> + <val2>
"<val1> <val2> -" pushes result of <val1> - <val2>
"<val1> <val2> *" pushes result of <val1> multiplied by <val2>
"<val1> <val2> /" pushes result of <val1> divided by <val2>
"<val1> <val2> **" pushes result of <val1> raised to the power <val2>
"<val> neg" pushes negated <val> (flips sign of value)
"<val> dup" pushes "<val> <val>" (duplicates value)
"<val1> <val2> swap" pushes "<val2> <val1>" (exchanges values)
"<val> abs" pushes absolute value of <val> (makes negative values positive)
"<val1> <val2> diff" pushes difference between values as a positive number
"<val1> ... <valN> sum" replaces all values by their sum
"<val1> ... <valN> min" replaces all values by their minimum
"<val1> ... <valN> max" replaces all values by their maximum
"<val1> ... <valN> sort" reorders all values into ascending order
"<val1> ... <valN> rev" reverses the current order of all values

$0 has been written 2003 by Guenther Brunthaler
END
if ($ARGV[0] =~ m!^ (?: (?: / | --? ) (?: \? | h (?: elp )? ) )? $!xi) {
   print $usage;
   exit;
}
$minute_seconds= 60;
$hour_seconds= 60 * $minute_seconds;
$day_seconds= 24 * $hour_seconds;
$week_seconds= 7 * $day_seconds;
$year_days= ((3 * 365 + 366) * 100 - 4 + 1) / 400;
$year_seconds= $year_days * $day_seconds;
$year_months= 12;
$month_seconds= $year_seconds / $year_months;
foreach (@ARGV) {
   $op= ${{
        '+' => sub {my($a1, $a2)= splice @s, -2; $a1 + $a2}
      , '-' => sub {my($a1, $a2)= splice @s, -2; $a1 - $a2}
      , '*' => sub {my($a1, $a2)= splice @s, -2; $a1 * $a2}
      , '/' => sub {my($a1, $a2)= splice @s, -2; $a1 / $a2}
      , 'neg' => sub {-pop @s}
      , 'dup' => sub {$s[-1]}
      , 'swap' => sub {reverse splice @s, -2}
      , 'abs' => sub {my $a= pop @s; $a < 0 ? -$a : $a}
      , 'diff' => sub {
         my($a1, $a2)= splice @s, -2; $a1 < $a2 ? $a2 - $a1 : $a1 - $a2
      }
      , '**' => sub {my($a1, $a2)= splice @s, -2; $a1 ** $a2}
      , 'sort' => sub {sort {$a <=> $b} splice @s}
      , 'sum' => sub {
         my $m= 0;
         $m+= $_ foreach @s;
         splice @s;
         return $m;
      }
      , 'min' => sub {
         my $m;
         foreach (@s) {$m= $_ if !defined($m) || $_ < $m}
         splice @s;
         return $m;
      }
      , 'max' => sub {
         my $m;
         foreach (@s) {$m= $_ if !defined($m) || $_ > $m}
         splice @s;
         return $m;
      }
      , 'rev' => sub {reverse splice @s}
   }}{$_};
   if ($op) {
      push @s, &$op;
   }
   else {
      my($yy, $mm, $dd, $y, $m, $w, $d, $h, $n, $s)= /
         ^
         # Date part
         (?:
            # ISO-format.
            (?:
               # YYYY-MM...
               (\d+) \s* - \s* (\d+)
               (?:
                  # ...-DD
                  \s* - \s* (\d+)
               )?
            )?
         |
            # Suffix-format.
            (?: (\d+) \s* y (?: ear s? )? )?
            (?: [\s,]* (\d+) \s* m (?: onth s? )? )?
            (?: [\s,]* (\d+) \s* w (?: eek s? )? )?
            (?: [\s,]* (\d+) \s* d (?: ay s? )? )?
         )
         # Time part.
         (?: [\s,]* (\d+) (?=\D | $) \s* (?: h | hour s? )? )?
         (?: [\s,:.]* (\d+) (?=\D | $) \s* (?: n | minute s? )? )?
         (?: [\s,:.]* (\d+) (?=\D | $) \s* (?: s (?: econd s? )? )? )?
         $
      /xi;
      if ($yy || $mm || $dd) {
         ($y, $m, $d)= ($yy, $mm - 1, $dd - 1);
      }
      $u= 1;
      foreach ($y, $m, $w, $d, $h, $n, $s) {
         if (defined) {$u= 0}
         else {$_= 0}
      }
      die "Bad time or operator '$_'" if $u;
      push @s
         , $y * $year_seconds + $m * $month_seconds + $w * $week_seconds
         + $d * $day_seconds  + $h * $hour_seconds + $n * $minute_seconds + $s
      ;
   }
}
foreach $v (@s) {
   @r= ();
   foreach (
        ['year', $year_seconds]
      , ['month', $month_seconds]
      , ['day', $day_seconds]
      , ['hour', $hour_seconds]
      , ['minute', $minute_seconds]
      , ['second', 1]
   ) {
      my($a, $u)= (int($v / $_->[1]), $_->[0]);
      $u.= 's' if $a != 1;
      push @r, $a . ' ' . $u if $a != 0;
      $v-= $a * $_->[1];
   };
   @r=('0 seconds') unless @r;
   print join(', ', @r), "\n";
}
