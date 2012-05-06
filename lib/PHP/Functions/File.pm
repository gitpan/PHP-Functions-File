use constant FILE_USE_INCLUDE_PATH => 1;
use constant LOCK_EX               => 2;
use constant FILE_APPEND           => 8;

package PHP::Functions::File;

use strict;
use warnings;

use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(file_get_contents file_put_contents);
$VERSION = '0.01';

use Carp qw(carp croak);

sub file_get_contents {
	my ($filename, $use_include_path, $context, $offset, $maxlen) = @_;

	if(!defined($filename)) {
		warn "first arg is required";
		return 0;
	}

	$use_include_path = defined($use_include_path) ? $use_include_path : 0;
	$offset           = defined($offset)  ? $offset  : -1;

	my $protocol = "default";
	if($filename =~ /^([^:]+):\/\/(.+)/) {
		$protocol  = lc $1;
		$filename = $2;
	}

	my $return;

	if($protocol eq "file") {
		if($use_include_path) {
			use File::Spec;
			my $filepath;
			foreach my $ip (@INC) {
				$filepath =  File::Spec->catfile($ip, $filename);
				my $break = 0;
				if( -e $filepath)
				{
					$filename = $filepath;
					last;
				}
			}
		}
		$protocol = "default";
	}

	if($protocol eq "default") {
		open(IN, $filename);
		while(<IN>)
		{
			$return .= $_;
		}
		close(IN);

		return $return;
	}
	elsif($protocol eq "http" || $protocol eq "https" ) {
		use LWP::UserAgent;
		use HTTP::Request;
		use HTTP::Response;

		my $proxy = new LWP::UserAgent;
		my $req   = HTTP::Request->new('GET', $protocol . "://". $filename);
		my $res   = $proxy->request($req);

		if($res->is_success) {
			return $res->content;
		}
		else {
			warn "file_get_contents(" . $res->base . "): failed to open stream: HTTP request failed! " . $res->code . " " . $res->message;
			return 0;
		}
	}
=cut_start
	elsif ($protocol eq "ftp" || $protocol eq "ftps") {
		use IO::Socket;

		my $username = "anonymous";
		my $password = "anonymous";
		my $hostname;

		if($filename =~ /^([^:]+):([^@]+)@([^\/]+)(.+)/) {
			$username = $1;
			$password = $2;
			$hostname = $3;
			$filename = $4;
		}

		my $socket;

		#@todo error handling
		if($protocol eq "ftp") {
			$socket = IO::Socket::INET->new(PeerAddr => $hostname,
											PeerPort => 20,
											Proto    => 'tcp',
											);
		}
		#@todo ftps support. IO::Socket::SSL

		if(!$socket) {
			warn "cannot open socket for ftp.";
			return 0;
		}
		print $socket "USER " . $username;
		print $socket "PASS " . $password;
		print $socket "SYST";
		#@todo TYPE, SIZE , PORT / PASV, RETR, MDTM
		print $socket "QUIT";
		$socket->flush();
		$socket->close();
	}
=cut
	else {
		warn "Protocol not supported";
		return 0;
	}
}

sub file_put_contents {
	my ($filename, $data, $flags, $context) = @_;

	if(!defined($filename)) {
		warn "first arg is required";
		return 0;
	}

	my $use_include_path;
	my $file_append;
	my $lock_ex;

	my $protocol = "default";
	if($filename =~ /^([^:]+):\/\/(.+)/) {
		$protocol  = lc $1;
		$filename = $2;
	}

	if($protocol eq "file") {
		if($use_include_path) {
			use File::Spec;
			my $filepath;
			foreach my $ip (@INC) {
				$filepath =  File::Spec->catfile($ip, $filename);
				my $break = 0;
				if( -e $filepath)
				{
					$filename = $filepath;
					last;
				}
			}
		}
		$protocol = "default";
	}

	if($protocol eq "default") {
		open(OUT, ">".$filename);
		print OUT $data;
		close(IN);
		return -s $filename;
	}
=cut_start
	elsif ($protocol eq "ftp" || $protocol eq "ftps") {
		#@todo ftp/ftps support
	}
=cut
	else {
		warn "Protocol not supported";
		return 0;
	}
}

1;
__END__
=head1 NAME

PHP::Functions::File - Transplant of file_get_contents/file_put_contentsl function of PHP

=head1 SYNOPSIS

  #file_get_contents
  use PHP::Functions::File qw(file_get_contents);
  string file_get_contents ( string $filename [, bool $use_include_path = 0 [, hash $context [, int $offset = -1 [, int $maxlen ]]]] )

  filename         : Name of the file to read.
  use_include_path : If ture, search for filename in the include directory.
  context          : Not supported now.
  offset           : Not supported now.
  maxlen           : Not supported now.

  #file_put_contents
  use PHP::Functions::File qw(file_put_contents);
  int file_put_contents ( string $filename , string $data [, int $flags = 0 [, hash $context ]] )

  filename: Path to the file where to write the data.
  data    : The data to write.
  flags   : Not supported now.
  context : Not supported now.

=head1 DESCRIPTION

This module offers perl function resemble file_get_contents/file_put_contents on PHP.
Perl 5.8 or higher is required.

=head1 SEE ALSO

L<http://www.php.net/manual/en/function.file-get-contents.php>
L<http://www.php.net/manual/en/function.file-put-contents.php>

=head1 To Do

- multiprotocol support. (Currently only http/file protocols are supported.)
- context support.

=head1 AUTHOR

Tomohide Nagashima E<lt>tnaga@cpan.orgE<gt>

=cut