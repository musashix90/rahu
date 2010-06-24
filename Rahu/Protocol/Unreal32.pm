package Rahu::Protocol::Unreal32;

use Rahu::Util qw(ircsend handle_event in_debugchan debug);
use Rahu::Conf qw(rahu);

my %user;

sub init_link {
	ircsend("PASS :@{[rahu_conf_linkpass]}");
	ircsend("PROTOCTL VL");
	ircsend("SERVER @{[rahu_conf_linkname]} 1 :U0-*-@{[rahu_conf_linkuuid]} @{[rahu_conf_linkdesc]}");
	ircsend("NICK @{[rahu_conf_botnick]} 1 @{[time()]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} @{[rahu_conf_linkname]} 0 +Sioq @{[rahu_conf_bothost]} :@{[rahu_conf_botgecos]}");
	ircsend(":@{[rahu_conf_botnick]} JOIN @{[rahu_conf_debugchan]}");
	ircsend(":@{[rahu_conf_botnick]} MODE @{[rahu_conf_debugchan]} +o @{[rahu_conf_botnick]} 0");
	in_debugchan(1);
}

sub irc_parse {
	my ($caller, $msg) = @_;
	debug("< $msg");
	if ($msg =~ /^NICK (.*) (.*) (.*) (.*) (.*) (.*) (.*) :(.*)$/) {
		my ($nick, $hops, $ts, $ident, $host, $src, $noidea, $gecos) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
		handle_event("CONNECT", rahu_conf_botnick, $nick, $ident, $host, $gecos, $src);
		$user{$nick}{host} = $host;
		$user{$nick}{ident} = $ident;
		$user{$nick}{gecos} = $gecos;
		$user{$nick}{server} = $src;
	}
	elsif ($msg =~ /^:(\S+) NICK (\S+) (\d+)$/) {
		my ($oldnick, $newnick, $ts) = ($1, $2, $3);
		handle_event("NICK", rahu_conf_botnick, $oldnick, $newnick, $user{$oldnick}{ident}, $user{$oldnick}{host}, $user{$oldnick}{gecos});
		$user{$newnick} = $user{$oldnick};
		delete($user{$oldnick});
	}
	elsif ($msg =~ /^PING :(.*)$/) {
		ircsend("PONG $1");
	}
	elsif ($msg =~ /^:(\S+) NOTICE (.*) :(.*)$/) {
		my ($src, $tgt, $msg) = ($1, $2, $3);
		handle_event("NOTICE", $tgt, $src, $tgt, $msg);
	}
	elsif ($msg =~ /^:(\S+) QUIT :(.*)$/) {
		my ($nick, $reason) = ($1, $2);
		handle_event("QUIT", rahu_conf_botnick, $nick, $user{$nick}{ident}, $user{$nick}{host}, $user{$nick}{gecos}, $user{$nick}{server}, $reason);
		delete $user{$nick};
	}
	elsif ($msg =~ /:(.*) WHOIS (.*) :.*$/) {
		ircsend(":@{[rahu_conf_linkname]} 311 $1 @{[rahu_conf_botnick]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} * :@{[rahu_conf_botgecos]}");
		ircsend(":@{[rahu_conf_linkname]} 312 $1 @{[rahu_conf_botnick]} @{[rahu_conf_linkname]} :@{[rahu_conf_linkdesc]}");
		ircsend(":@{[rahu_conf_linkname]} 313 $1 @{[rahu_conf_botnick]} :is a Network Service");
		ircsend(":@{[rahu_conf_linkname]} 318 $1 @{[rahu_conf_botnick]} :End of /WHOIS list.");
	}
}

1;
