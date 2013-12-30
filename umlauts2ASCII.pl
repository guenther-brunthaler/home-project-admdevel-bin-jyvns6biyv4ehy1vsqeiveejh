#! /usr/bin/perl -w
use locale;
while (defined($_= <>)) {
   s/Ä/Ae/g;
   s/Ö/Oe/g;
   s/Ü/Ue/g;
   s/ä/ae/g;
   s/ö/oe/g;
   s/ü/ue/g;
   s/ß/ss/g;
   s/€/EUR/g;
   s/²/^2/g;
   s/³/^3/g;
   print;
}
