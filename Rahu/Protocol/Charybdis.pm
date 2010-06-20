package Rahu::Protocol::Charybdis;

use Rahu::Util qw(ircsend);
use Rahu::Conf qw(rahu);

my $botuuid = rahu_conf_linkuuid."AAAAAB";
my $signon = time();
my $is_in_debugchan;
my %user;

sub init_link {
	ircsend("PASS @{[rahu_conf_linkpass]} TS 6 :@{[rahu_conf_linkuuid]}");
	ircsend("CAPAB :KLN UNKLN GLN EUID");
	ircsend("SERVER @{[rahu_conf_linkname]} 1 :@{[rahu_conf_linkdesc]}");
	$is_in_debugchan = 0;
}

sub irc_parse {
	my ($caller, $msg) = @_;
	print "< $msg\n";
	if ($msg =~ /^CAPAB :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} EUID rahu 1 @{[time]} +ioS rahu @{[rahu_conf_linkname]} 0 $botuuid * * :rahu");
	}
	elsif ($msg =~ /^:(.*) SJOIN (.*) (.*) (.*) :(.*)$/) {
		if ($3 eq rahu_conf_debugchan && $is_in_debugchan == 0) {
			ircsend(":@{[rahu_conf_linkuuid]} SJOIN $2 $3 + :@".$botuuid);
			$is_in_debugchan++;
		}
	}
	elsif ($msg =~ /^PING :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} PONG @{[rahu_conf_linkname]} :$1");
	}
	elsif ($msg =~ /^:(.*) WHOIS (.*) :(.*)$/) {
		ircsend(":@{[rahu_conf_linkuuid]} 311 $1 rahu rahu @{[rahu_conf_linkname]} * :rahu");
		ircsend(":@{[rahu_conf_linkuuid]} 312 $1 rahu @{[rahu_conf_linkname]} :@{[rahu_conf_linkdesc]}");
		ircsend(":@{[rahu_conf_linkuuid]} 313 $1 rahu :is a Network Service");
		ircsend(":@{[rahu_conf_linkuuid]} 318 $1 rahu :End of WHOIS");
	}
}

1;
