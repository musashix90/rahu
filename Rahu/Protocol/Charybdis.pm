package Rahu::Protocol::Charybdis;

use Rahu::Util qw(ircsend handle_event in_debugchan debug);
use Rahu::Conf qw(rahu);

my $botuuid = rahu_conf_linkuuid."AAAAAB";
my $signon = time();
my $is_in_debugchan;
my %user;
my %server;
my $waiting_for_server;
my $first_ping;

sub init_link {
	ircsend("PASS @{[rahu_conf_linkpass]} TS 6 :@{[rahu_conf_linkuuid]}");
	ircsend("CAPAB :KLN UNKLN GLN EUID EOB");
	ircsend("SERVER @{[rahu_conf_linkname]} 1 :@{[rahu_conf_linkdesc]}");
	$is_in_debugchan = 0;
}

sub irc_parse {
	my ($caller, $msg) = @_;
	debug("< $msg");
	if ($msg =~ /^CAPAB :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} EUID @{[rahu_conf_botnick]} 1 @{[time]} +ioS @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} 0 $botuuid * * :@{[rahu_conf_botnick]}");
		$user{$botuuid}{nick} = rahu_conf_botnick;
	}
	elsif ($msg =~ /^:(.*) EUID (.*) (.*) (.*) (.*) (.*) (.*) (.*) (.*) (.*) (.*) :(.*)$/) {
		my ($src, $nick, $hops, $ts, $modes, $ident, $host, $ip, $uuid, $realhost, $account, $gecos) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);
		handle_event("CONNECT", rahu_conf_botnick, $nick, $ident, $host, $gecos, $server{$src}{name});
		$user{$uuid}{nick} = $nick;
		$user{$uuid}{host} = $host;
		$user{$uuid}{ident} = $ident;
		$user{$uuid}{gecos} = $gecos;
		$user{$uuid}{server} = $server{$src}{name};
	}
	elsif ($msg =~ /^:(\S+) NICK (.*) :(\d+)$/) {
		handle_event("NICK", rahu_conf_botnick, $user{$1}{nick}, $2, $user{$1}{ident}, $user{$1}{host}, $user{$1}{gecos});
		$user{$1}{nick} = $2;
	}
	elsif ($msg =~ /^:(\S+) NOTICE (.*) :(.*)$/) {
		my ($src, $tgt, $msg) = ($1, $2, $3);
		handle_event("NOTICE", $tgt, $user{$src}{nick}, $user{$tgt}{nick}, $msg);
	}
	elsif ($msg =~ /^PASS (.*) :(.*)$/) {
		$waiting_for_server = $2;
	}
	elsif ($msg =~ /^PING :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} PONG @{[rahu_conf_linkname]} :$1");
		if (!defined($first_ping)) {
			if (!$is_in_debugchan) {
				ircsend(":@{[rahu_conf_linkuuid]} SJOIN @{[time]} @{[rahu_conf_debugchan]} + :@".$botuuid);
				in_debugchan(1);
				$is_in_debugchan++;
			}
			$first_ping++;
		}
	}
	elsif ($msg =~ /^:(\S+) QUIT :(.*)$/) {
		handle_event("QUIT", rahu_conf_botnick, $user{$1}{nick}, $user{$1}{ident}, $user{$1}{host}, $user{$1}{gecos}, $user{$1}{server}, $2);
		delete $user{$1};
	}
	elsif ($msg =~ /^SERVER (.*) (.*) :(.*)$/) {
		if (defined($waiting_for_server)) {
			$server{$waiting_for_server}{name} = $1;
			undef $waiting_for_server;
		}
	}
	elsif ($msg =~ /^:(.*) SID (.*) (.*) (.*) :(.*)$/) {
		my ($src, $linkname, $hops, $uid, $gecos) = ($1, $2, $3, $4, $5);
		$server{$uid}{name} = $linkname;
	}
	elsif ($msg =~ /^:(.*) SJOIN (.*) (.*) (.*) :(.*)$/) {
		my ($src,$ts,$chan,$modes,$nick) = ($1, $2, $3, $4, $5);
		if ($3 eq rahu_conf_debugchan && $is_in_debugchan == 0) {
			if (!defined($first_ping)) {
				ircsend(":@{[rahu_conf_linkuuid]} SJOIN $2 $3 + :@".$botuuid);
				in_debugchan(1);
				$is_in_debugchan++;
			}
		}
	}
	elsif ($msg =~ /^:(.*) WHOIS (.*) :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} 311 $1 @{[rahu_conf_botnick]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} * :@{[rahu_conf_botgecos]}");
		ircsend(":@{[rahu_conf_linkuuid]} 312 $1 @{[rahu_conf_botnick]} @{[rahu_conf_linkname]} :@{[rahu_conf_linkdesc]}");
		ircsend(":@{[rahu_conf_linkuuid]} 313 $1 @{[rahu_conf_botnick]} :is a Network Service");
		ircsend(":@{[rahu_conf_linkuuid]} 318 $1 @{[rahu_conf_botnick]} :End of WHOIS");
	}
}

1;
