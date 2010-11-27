#!/usr/bin/perl
use strict;

use IO::Socket::INET;
use Cwd qw(abs_path);
use File::Basename;
use Getopt::Long;

BEGIN {
	sub PREFIX { return dirname(abs_path($0)); }
	die "It appears that you don't have a config file in @{[PREFIX]}" if !-e PREFIX."/rahu.conf";
}

chdir PREFIX;
use lib PREFIX;

our $debug;
my $help;
GetOptions('debug' => \$debug,
           'help' => \$help);

if (defined $help) {
	print qq(rahu IRC service
Usage: rahu.pl [options]

Options:
    --help      Displays this help message
    --debug     Does not daemonize rahu, prints in STDOUT
);
exit;
}

use Rahu::Conf qw(rahu);
use Rahu::Util qw(find_protocol find_module debug);

die "It seems you haven't set a protocol to link yet!" if rahu_conf_protocol eq "undef" || rahu_conf_protocol eq "";
my $protocol = "Rahu::Protocol::".find_protocol(rahu_conf_protocol);
$protocol =~ s/\.pm$//;

require "Rahu/Protocol/". find_protocol(rahu_conf_protocol);

if (rahu_conf_modules ne "undef" || rahu_conf_modules ne "") {
	my @modules = split(/\s?\,\s?/, rahu_conf_modules);

	foreach my $module (@modules) {
		print "Loading module $module\n";
		require "Rahu/Module/". find_module($module);
	}
}

our $sock = IO::Socket::INET->new(PeerAddr => rahu_conf_serveraddr,
                                 PeerPort => rahu_conf_serverport,
                                 Proto    => 'tcp') or debug("[".scalar localtime()."] Unable to connect");
my $lastconn = time();

daemonize() if !defined $debug;

# oh how this has UGLY written all over it
while (1) {
	if (!defined($sock)) {
		if ((time - $lastconn) >= 15) {
			debug("[".scalar localtime()."] Attempting to reconnect...");
			$sock = IO::Socket::INET->new(PeerAddr => rahu_conf_serveraddr,
                                 PeerPort => rahu_conf_serverport,
                                 Proto    => 'tcp') or debug("[".scalar localtime()."] Unable to connect");
			$lastconn = time();
		}
	} else {
		$protocol->init_link();
		while (my $input = <$sock>) {
			$input =~ s/[\r\n]//g;
			$protocol->irc_parse($input);
		}
		debug("[".scalar localtime()."] Lost connection to the server.");
		close($sock);
		undef $sock;
		next;
	}
}

sub daemonize() {
	close STDIN;
	close STDOUT;
	close STDERR;
	open(STDIN, '>', '/dev/null');
	open(STDOUT, '>', '/dev/null');
	open(STDERR,  '>', '/dev/null');
	if(fork()) { exit(0) }
}

