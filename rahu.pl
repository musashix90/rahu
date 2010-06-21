#!/usr/bin/perl
use strict;
use IO::Socket::INET;
use Cwd qw(abs_path);
use File::Basename;

BEGIN {
	sub PREFIX { return dirname(abs_path($0)); }
	die "It appears that you don't have a config file in @{[PREFIX]}" if !-e PREFIX."/rahu.conf";
}

chdir PREFIX;
use lib PREFIX;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(find_protocol find_module);

die "It seems you haven't set a protocol to link yet!" if rahu_conf_protocol eq "undef" || rahu_conf_protocol eq "";
my $protocol = "Rahu::Protocol::".find_protocol(rahu_conf_protocol);
$protocol =~ s/\.pm$//;

require "Rahu/Protocol/". find_protocol(rahu_conf_protocol);

if (rahu_conf_modules ne "undef" || rahu_conf_modules ne "") {
	my @modules = split(/\s?\,\s?/, rahu_conf_modules);

	foreach my $module (@modules) {
		print $module."\n";
		require "Rahu/Module/". find_module($module);
	}
}

our $sock = IO::Socket::INET->new(PeerAddr => rahu_conf_serveraddr,
                                 PeerPort => rahu_conf_serverport,
                                 Proto    => 'tcp') or print "[".scalar localtime()."] Unable to connect\n";
my $lastconn = time();

# oh how this has UGLY written all over it
while (1) {
	if (!defined($sock)) {
		if ((time - $lastconn) >= 5) {
			print "[".scalar localtime()."] Attempting to reconnect...\n";
			$sock = IO::Socket::INET->new(PeerAddr => rahu_conf_serveraddr,
                                 PeerPort => rahu_conf_serverport,
                                 Proto    => 'tcp') or print "[".scalar localtime()."] Unable to connect\n";
			$lastconn = time();
		}
	} else {
		$protocol->init_link();
		while (my $input = <$sock>) {
			$input =~ s/[\r\n]//g;
			$protocol->irc_parse($input);
		}
		print "[".scalar localtime()."] Lost connection to the server.\n";
		close($sock);
		undef $sock;
		next;
	}
}
