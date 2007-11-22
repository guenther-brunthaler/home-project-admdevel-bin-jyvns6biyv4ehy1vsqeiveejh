# Create, Check or Update MD5 files.
# $Id: /caches/xsvn/admdevel/trunk/prj/shared_bin_in_path_9wewpie7d5tawvtr9qf842c1z/md5.pl 11 2006-11-06T23:14:31.537884Z root(xternal)  $


use strict;
use Pod::Usage;
use Getopt::Std;
use File::Spec;


my(%opt);


sub HELP_MESSAGE {
 my($sw)= $_[4];
 Getopt::Std::version_mess($sw);
 pod2usage(qw/-verbose 2 -exitval 0/);
}


sub build_path(\%) {
 my $list= shift;
 my @d;
 while (defined $list->{dir}) {
  push @d, $list->{dir};
  $list= $list->{parent};
 }
 $d[0]= '.' unless @d;
 File::Spec->catdir(reverse @d);
}


sub handle_cdir(\%) {
 my $parent= shift;
 local(*DIR);
 my(@d);
 if (opendir DIR, '.') {
  my $e;
  while (defined($e= readdir DIR)) {
   push @d, $e;
  }
  closedir DIR or die $!;
 }
 else {
  warn "Cannot examine directory '" . build_path(%$parent) . "': $!";
  return;
 }
 foreach (File::Spec->no_upwards(@d)) {
 }

  if (-d) {
   if (!-r _) {
    warn "cannot access directory '" . build_path(%$parent) . "'";
   }
   else {
   }
  }
  elsif (-f _) {
   if (!-r _) {
    warn "cannot read file '" . build_path(%$parent) . "'";
   }
   else {
   }
  }
  else {
   warn "ignoring file system object '" . build_path(%$parent) . "'" if $opt{v};
  }

}


our($VERSION)= q$Revision: 11 $ =~ /(\d+\.\d+)/;
$Getopt::Std::STANDARD_HELP_VERSION= 1;
getopts('ugcv', \%opt);
$opt{u}= !$opt{c};
handle_cdir %{({})};


__END__
 

=head1 NAME

md5 - create, check or update MD5 files

=head1 SYNOPSIS

md5: same as md5 -u

md5 -u: update

md5 -g: gather/update checksum.md5

md5 -c: check MD5 files

=head1 DESCRIPTION

=head2 Options

=over 4

=item --help

Prints a help message.

=item --version

Print the script version.

=item -v

Set verbose reporting mode.

=back

=head2 Examples

=head1 TO DO

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Guenther Brunthaler

=cut
