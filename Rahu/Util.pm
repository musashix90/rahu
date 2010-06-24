package Rahu::Util;

use strict;
use Exporter 'import';
use Cwd qw(getcwd);

BEGIN {
	our @EXPORT = qw(find_protocol ircsend find_module addhandler handle_event in_debugchan debug);
}

my @handles;
my @buffer;
my $in_debugchan = 0;
my %users;

sub addhandler {
	my ($event, $sub) = @_;
	push @handles, { event => $event, cmd => $sub };
}

sub debug {
	my ($msg) = @_;
	if (defined $main::debug) {
		print "[".scalar localtime()."] $msg\n";
	}
}

sub find_protocol {
	my ($protocol) = @_;
	opendir (DIR, main::PREFIX."/Rahu/Protocol/") or die("Error opening ".main::PREFIX."/Rahu/Protocol/");
	while ((my $file = readdir(DIR))) {
		if (lc $file =~ /^${protocol}\.pm$/i) {
			return $file;
		}
	}
	closedir(DIR);
}

sub find_module {
	my ($module) = @_;
	opendir (DIR, main::PREFIX."/Rahu/Module/") or die("Error opening ".main::PREFIX."/Rahu/Module/");
	while ((my $file = readdir(DIR))) {
		if (lc $file =~ /^${module}\.pm$/i) {
			return $file;
		}
	}
	closedir(DIR);
}

sub handle_event {
	my $event = shift @_;
	no strict 'refs';
	for (@handles) {
		if ($_->{'event'} eq $event) {
			$_->{'cmd'}->( @_ );
		}
	}
}

sub in_debugchan {
	my ($result) = @_;
	$in_debugchan = $result;
	if ($result == 1) {
		for (@buffer) {
			print $main::sock $_->{'msg'}."\r\n";
			debug("> ".$_->{'msg'});
		}
	}
}

sub ircsend {
	my ($msg) = @_;
	if ($msg =~ /^:(.*) PRIVMSG (.*)$/ && $in_debugchan == 0) {
		push @buffer, { msg => $msg };
	} else {
		print $main::sock $msg."\r\n";
		debug("> $msg");
	}
}

1;
