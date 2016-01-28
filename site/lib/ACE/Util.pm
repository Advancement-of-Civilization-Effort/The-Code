#!perl
# vim: ts=2 et noai nowrap

package ACE::Util;
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
sub read_lnk {
  use Win32::Shortcut;
  my $link = Win32::Shortcut->new();
  $link->Load($_[0]);
  #print "Shortcut to: $link->{'Path'} $link->{'Arguments'} \n";
  my $cmd = undef;
  if ($link->{'Arguments'}) {
    $cmd = join' ',$link->{'Path'},$link->{'Arguments'};
  } else {
    $cmd = $link->{'Path'};
  }
  $link->Close();
  return $cmd;
}
# ====================================================
sub pause {local$|=1;local$/="\n";print'...';my$a=<STDIN>}

# ------------------------
sub md5hash {
 my $txt = join'',@_;
 use Digest::MD5 qw();
 my $msg = Digest::MD5->new() or die $!;
    $msg->add($txt);
 my $digest = lc( $msg->hexdigest() );
 return $digest; #hex form !
}
# ------------------------
sub githash {
 my $txt = join'',@_;
 use Digest::SHA1 qw();
 my $msg = Digest::SHA1->new() or die $!;
    $msg->add(sprintf "blob %u\0",length($txt));
    $msg->add($txt);
 my $digest = lc( $msg->hexdigest() );
 return $digest; #hex form !
}
# ------------------------

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
sub wiki2yml {
  my $url = @_[0];
  my $page = get_http($url);
  my $body = substr($page,index($page,"\r\n\r\n")+4); # skip header
  my ($start,$stop) = (index($body,'<!-- start content -->'),
                 index($body,'<!-- end content -->') );
  my $content = substr($body,$start,$stop-$start); # isolate content
     #$content =~ s,<h\d>.*</h\d>,,go; # remove headers h1,h2,...
  my ($start,$stop) = (index($content,'<textarea name="wpTextbox1" '),
                 index($content,'</textarea>') );
  my $yml = substr($content,$start,$stop-$start); # extract yml data as captured by user.
     $yml =~ s/<[^>]+>//go; # remove html tags
     $yml =~ s/&quot;/"/go; # replace specials
     $yml =~ s/&gt;/>/go;
     $yml =~ s/&lt;/</go;
     # filter headers, and other comments
     $yml = join"\n",grep !/^[#=-]|^$/, split"\n",$yml;
     return $yml;
}
# ----------------------------------------------------
sub get_http {
  my $socket;
  my $agent = $0;
  use Socket;

  my ($url) = @_;
  my ($host,$document) = ($url =~ m{http://([^/]+)(/.*)?}); #/#
  my $port = 80;
  $document = '/' unless $document;
  #print "$host $port\n";
  my $iaddr = inet_aton($host);
  my $paddr = sockaddr_in($port, $iaddr);
  my $proto = (getprotobyname('tcp'))[2];
  socket($socket, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
  connect($socket, $paddr) or do { warn "connect: $!"; return 'HTTP/1.0 500 Error'."\r\n\r\nWarn: connect: $!\r\n" };
  select((select($socket),$|=1)[0]) ; binmode($socket);
  printf "GET %s HTTP/1.1\r\n",$document if $dbug;
  printf $socket "GET %s HTTP/1.1\r\n",$document;
  printf $socket "Host: %s\r\n",$host;
  printf $socket "User-Agent: %s\r\n",$agent; # some site requires an agent
  print  $socket "Connection: close\r\n";
  print  $socket "\r\n";
  local $/ = undef;
  my $buf = <$socket>;
  close $socket or die "close: $!";
  return $buf;
}
# ----------------------------------------------------
sub post_http {
  my $socket;
  my $agent = $0;
  use Socket;
  my ($url,$postData) = @_;
  my ($host,$document) = ($url =~ m{http://([^/]+)(/.*)?}); #/#
  my $port = 80;
  $document = '/' unless $document;
  #print "$host $port\n";
  my $iaddr = inet_aton($host);
  my $paddr = sockaddr_in($port, $iaddr);
  my $proto = (getprotobyname('tcp'))[2];
  socket($socket, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
  connect($socket, $paddr) or do { warn "connect: $!"; return 'HTTP/1.0 500 Error'."\r\n\r\nWarn: connect: $!\r\n" };
  select((select($socket),$|=1)[0]) ; binmode($socket);
  printf "GET %s HTTP/1.1\r\n",$document if $dbug;
  printf $socket "POST %s HTTP/1.1\r\n",$document;
  printf $socket "Host: %s\r\n",$host;
  printf $socket "User-Agent: %s\r\n",$agent; # some site requires an agent
  print  $socket "ContentType: application/x-www-form-urlencoded\r\n";
  printf $socket "ContentLength: %u\r\n",length($postData);
  print  $socket "Connection: close\r\n";
  print  $socket "\r\n";
  print  $socket $postData;
  local $/ = undef;
  my $buf = <$socket>;
  close $socket or die "close: $!";
  return $buf;
}
# ----------------------------------------------------
sub hdate { # return HTTP date (RFC-1123, RFC-2822) 
  my $DoW = [qw( Sun Mon Tue Wed Thu Fri Sat )];
  my $MoY = [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )];
  my ($sec,$min,$hour,$mday,$mon,$yy,$wday) = (gmtime($_[0]))[0..6];
  my ($yr4,$yr2) =($yy+1900,$yy%100);
  # Mon, 01 Jan 2010 00:00:00 GMT

  my $date = sprintf '%3s, %02d %3s %04u %02u:%02u:%02u GMT',
             $DoW->[$wday],$mday,$MoY->[$mon],$yr4, $hour,$min,$sec;
  return $date;
}
# ----------------------------------------------------
sub sdate { # return a human readable date ... but still sortable ...
  my $tic = int ($_[0]);
  my $ms = ($_[0] - $tic) * 1000;
     $ms = ($ms) ? sprintf('%04u',$ms) : '____';
  my ($sec,$min,$hour,$mday,$mon,$yy) = (localtime($tic))[0..5];
  my ($yr4,$yr2) =($yy+1900,$yy%100);
  my $date = sprintf '%04u-%02u-%02u %02u:%02u:%02u',
             $yr4,$mon+1,$mday, $hour,$min,$sec;
  return $date;
}
# ----------------------------------------------------
sub zdate { # return Zulu time 
  my ($sec,$min,$hour,$mday,$mon,$yy,$wday) = (gmtime($_[0]))[0..6];
  my ($yr4,$yr2) =($yy+1900,$yy%100);
  # 20130424T085606Z
  my $date = sprintf '%4u%02u%02uT%02u%02u%02uZ',
             $yr4,$mon+1,$mday,$hour,$min,$sec;
  return $date;
}
# ----------------------------------------------------
sub duration {
  my $n = shift;
  my ($hh,$mm,$ss);
  $ss = $n % 60;
  $n = int($n / 60);
  if ($n > 0) {
    $mm = $n % 60;
    $n = int($n / 60);
  }
  if ($n > 0) {
    $hh = $n % 24;
    $n = int($n / 24);
  }
  my $s = '';
  $s .= sprintf '%ud',$n if ($n > 0);
  $s .= sprintf ' %uh',$hh if ($hh > 0);
  $s .= sprintf ' %um',$mm if ($mm > 0);
  $s .= sprintf ' %us',$ss if ($ss > 0);
  return $s;
}
# ----------------------------------------------------
1; #$Source: /my/perl/module/from/ACE/Util.pm,v $

__DATA__

