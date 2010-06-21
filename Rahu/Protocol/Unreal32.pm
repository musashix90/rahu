package Rahu::Protocol::Unreal32;

use Rahu::Util qw(ircsend handle_event in_debugchan);
use Rahu::Conf qw(rahu);

sub init_link {
	ircsend("PASS :@{[rahu_conf_linkpass]}");
	ircsend("PROTOCTL VL");
	ircsend("SERVER @{[rahu_conf_linkname]} 1 :U0-*-@{[rahu_conf_linkuuid]} @{[rahu_conf_linkdesc]}");
	ircsend("NICK @{[rahu_conf_botnick]} 1 @{[time()]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} @{[rahu_conf_linkname]} 0 +Sioq @{[rahu_conf_bothost]} :@{[rahu_conf_botgecos]}");
	ircsend(":@{[rahu_conf_botnick]} JOIN @{[rahu_conf_debugchan]}");
	in_debugchan(1);
}

sub irc_parse {
	my ($caller, $msg) = @_;
	if ($msg =~ /^NICK (.*) (.*) (.*) (.*) (.*) (.*) (.*) :(.*)$/) {
		my ($nick, $hops, $ts, $ident, $realhost, $src, $noidea, $gecos) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
		handle_event("CONNECT", rahu_conf_botnick, $nick, $ident, $realhost, $gecos, $src);
	}
	elsif ($msg =~ /^PING :(.*)$/) {
		ircsend("PONG $1");
	}
	elsif ($msg =~ /^:(\S+) NOTICE (.*) :(.*)$/) {
		my ($src, $tgt, $msg) = ($1, $2, $3);
		handle_event("NOTICE", $tgt, $src, $tgt, $msg);
	}
	elsif ($msg =~ /:(.*) WHOIS (.*) :.*$/) {
		ircsend(":@{[rahu_conf_linkname]} 311 $1 @{[rahu_conf_botnick]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} * :@{[rahu_conf_botgecos]}");
		ircsend(":@{[rahu_conf_linkname]} 312 $1 @{[rahu_conf_botnick]} @{[rahu_conf_linkname]} :@{[rahu_conf_linkdesc]}");
		ircsend(":@{[rahu_conf_linkname]} 313 $1 @{[rahu_conf_botnick]} :is a Network Service");
		ircsend(":@{[rahu_conf_linkname]} 318 $1 @{[rahu_conf_botnick]} :End of /WHOIS list.");
	}
	print "< $msg\n";
}

1;
