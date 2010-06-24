package Rahu::Protocol::Insp12;

use Rahu::Util qw(ircsend in_debugchan handle_event debug);
use Rahu::Conf qw(rahu);

my $botuuid = rahu_conf_linkuuid."AAAAAA";
my $signon = time();
my $is_in_debugchan = 0;
my %user;

sub init_link {
	ircsend("SERVER @{[rahu_conf_linkname]} @{[rahu_conf_linkpass]} 0 @{[rahu_conf_linkuuid]} :@{[rahu_conf_linkdesc]}");
}

sub irc_parse {
	my ($caller, $msg) = @_;
	debug("< $msg");
	if ($msg =~ /^:(\S+) FJOIN (\S+) (\d+) (.*) :(.*)$/) {
		if (lc $2 eq lc rahu_conf_debugchan && $is_in_debugchan == 0) {
			ircsend(":@{[rahu_conf_linkuuid]} FJOIN $2 $3 $4 :,$botuuid");
			ircsend(":@{[rahu_conf_linkuuid]} FMODE $2 $3 +o $botuuid");
			$is_in_debugchan++;
			in_debugchan(1);
		}
	}
	elsif ($msg =~ /^:(.*) IDLE (.*)$/) {
		if ($2 eq $botuuid) {
			ircsend(":$2 IDLE ".$user{$1}{nick}." $signon 0");
		}
	}
	elsif ($msg =~ /^:(\S+) NICK (.*) (\d+)$/) {
		my ($src, $newnick, $ts) = ($1, $2, $3);
		handle_event("NICK", $botuuid, $user{$1}{nick}, $2, $user{$1}{ident}, $user{$1}{host}, $user{$1}{gecos});
		$user{$1}{nick} = $2;
	}
	elsif ($msg =~ /^:(\S+) NOTICE (.*) :(.*)$/) {
		my ($src, $tgt, $msg) = ($1, $2, $3);
		handle_event("NOTICE", $tgt, $user{$src}{nick}, $user{$tgt}{nick}, $msg);
	}
	elsif ($msg =~ /^:(.*) PING (.*) (.*)$/) {
		ircsend(":$3 PONG $3 $1");
	}
	elsif ($msg =~ /^:(\S+) QUIT :(.*)$/) {
		handle_event("QUIT", $botuuid, $user{$1}{nick}, $user{$1}{ident}, $user{$1}{host}, $user{$1}{gecos}, $user{$1}{server}, $2);
		delete $user{$1};
	}
	elsif ($msg =~ /^SERVER (.*) (.*) (.*) (.*) :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} BURST @{[time]}");
		ircsend(":@{[rahu_conf_linkuuid]} VERSION :rahu IRC Protection @{[rahu_version]}");
		ircsend(":@{[rahu_conf_linkuuid]} UID ".rahu_conf_linkuuid."AAAAAA @{[time]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} @{[rahu_conf_bothost]} @{[rahu_conf_botnick]} 0.0.0.0 @{[time]} +oik :@{[rahu_conf_botgecos]}");
		ircsend(":$botuuid OPERTYPE Service");
		ircsend(":@{[rahu_conf_linkuuid]} ENDBURST");
		$server{$4}{name} = $1;
		$user{$botuuid}{nick} = rahu_conf_botnick;
		$signon = time();
	}
	elsif ($msg =~ /^:(.*) SERVER (.*) (.*) (.*) (.*) :(.*)$/) {
		$server{$5}{name} = $2;
	}
	elsif ($msg =~ /^:(\S+) UID (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (.*) (.*) :(.*)$/) {
		my ($src, $uid, $ts, $nick, $host, $cloakedhost, $ident, $ip, $signon, $modes, $gecos) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
		$user{$uid}{nick} = $nick;
		$user{$uid}{host} = $host;
		$user{$uid}{ident} = $ident;
		$user{$uid}{gecos} = $gecos;
		$user{$uid}{server} = $server{$src}{name};
		handle_event("CONNECT", $botuuid, $nick, $ident, $host, $gecos, $server{$src}{name});
	}
}

1;
