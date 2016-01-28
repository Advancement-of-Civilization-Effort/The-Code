#!perl
# vim: ts=2 et noai nowrap

package ACE::Config;
# Note:
#   This work has been done during my ACE's time
# 
# -- Copyright ACE, 2015,2016 --
# ----------------------------------------------------
require Exporter;
@ISA = qw(Exporter);
# Subs we export by default.
@EXPORT = qw();
# Subs we will export if asked.
#@EXPORT_OK = qw(nickname);
@EXPORT_OK = grep { $_ !~ m/^_/ && defined &$_; } keys %{__PACKAGE__ . '::'};

use strict;
# The "use vars" and "$VERSION" statements seem to be required.
use vars qw/$dbug $VERSION/;
# ----------------------------------------------------
local $VERSION = sprintf "%d.%02d", q$Revision: 0.0 $ =~ /: (\d+)\.(\d+)/;
my ($State) = q$State: Exp $ =~ /: (\w+)/; our $dbug = ($State eq 'dbug')?1:0;
# ----------------------------------------------------
if (! -f '/dev/null') { # non-unix system
}

# ----------------------------------------------------
sub config { # create a setting file that has all the system config


}
# ----------------------------------------------------
sub flush { my $h = select($_[0]); my $af=$|; $|=1; $|=$af; select($h); }
# ----------------------------------------------------
sub cptime ($$) {
 my ($src,$trg) = @_;
 my ($atime,$mtime,$ctime) = (lstat($src))[8,9,10];
 #my $etime = ($mtime < $ctime) ? $mtime : $ctime;
 utime($atime,$mtime,$trg);
}
# ----------------------------------------------------
sub copy ($$) {
 my ($src,$trg) = @_;
 local *F1, *F2;
 return -1 unless -r $src;
 return -2 unless (! -e $trg || -w $trg);
 open F2,'>',$trg or warn "-w $trg $!"; binmode(F2);
 open F1,'<',$src or warn "-r $src $!"; binmode(F1);
 local $/ = undef;
 my $tmp = <F1>; print F2 $tmp;
 close F1;

 my ($atime,$mtime,$ctime) = (lstat(F1))[8,9,10];
 #my $etime = ($mtime < $ctime) ? $mtime : $ctime;
 utime($atime,$mtime,$trg);
 close F2;
 return $?;
}
# ----------------------------------------------------
sub update_copy {
  my $src = shift;
  my $dst = shift;
	local *F; open F,'<',$src or die $!;
	local $/ = undef; my $buf = <F>; close F;
	foreach my $k (sort keys %{$_[0]}) {
		 $buf =~ s/\%$k\%/$_[0]->{$k}/g;
	}
	open F,'>',$dst or die $!;
  print F $buf;
	close F;
  return $?;
}
# ----------------------------------------------------
sub inplace_update {
  my $f = shift;
	local *F; open F,'+<',$f or die $!;
	local $/ = undef;
	my $buf = <F>;
	foreach my $k (sort keys %{$_[0]}) {
		 $buf =~ s/%$k%/$_[0]->{$k}/g;
	}
	seek(F,0,0); # inplace substitution !
	print F $buf;
	truncate(F,tell(F));
	close F;
	return $?;
}
# ----------------------------------------------------
sub findpath {
  my $es = 'es.exe';
  my $query = shift; # join' ', map { sprintf '"%s"',$_ } @_;
  my $cmd = sprintf '"%s" -i -n 2 %s "!\QNAP" |',$es,$query;
  open my $es,$cmd or warn $!;
  local $/ = "\n";
  my $path = <$es>; chomp $path;
  print "path: $path\n" if ($::dbug || $dbug);
  while (<$es>) { print " $_" if ($::dbug || $dbug) }
  close $es;
  return undef unless -e $path;
  return $path;
}
# ----------------------------------------------------
1; #$Source: /my/perl/module/from/ACE/Config.pm,v $

__DATA__

