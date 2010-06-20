package Rahu::Protocol::Insp12;

use Rahu::Util qw(ircsend);
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
	print "< $msg\n";
	if ($msg =~ /^SERVER .*$/) {
		ircsend(":@{[rahu_conf_linkuuid]} BURST @{[time]}");
		ircsend(":@{[rahu_conf_linkuuid]} VERSION :rahu IRC Protection @{[rahu_version]}");
		ircsend(":@{[rahu_conf_linkuuid]} UID ".rahu_conf_linkuuid."AAAAAA @{[time]} @{[rahu_conf_botnick]} @{[rahu_conf_bothost]} @{[rahu_conf_bothost]} @{[rahu_conf_botnick]} 0.0.0.0 @{[time]} +oik :@{[rahu_conf_botnick]}");
		ircsend(":$botuuid OPERTYPE Service");
		ircsend(":@{[rahu_conf_linkuuid]} ENDBURST");
		$signon = time();
	}
	elsif ($msg =~ /^:(.*) PING (.*) (.*)$/) {
		ircsend(":$3 PONG $3 $1");
	}
	elsif ($msg =~ /^:(.*) FJOIN (.*) (.*) (.*) (.*)$/) {
		if ($2 eq rahu_conf_debugchan && $is_in_debugchan == 0) {
			ircsend(":@{[rahu_conf_linkuuid]} FJOIN @{[rahu_conf_debugchan]} $3 $4 :,$botuuid");
			ircsend(":@{[rahu_conf_linkuuid]} FMODE @{[rahu_conf_debugchan]} $3 +o $botuuid");
			$is_in_debugchan++;
		}
	}
	elsif ($msg =~ /^:(.*) IDLE (.*)$/) {
		if ($2 eq $botuuid) {
			ircsend(":$2 IDLE ".$user{$1}{nick}." $signon 0");
		}
	}
	elsif ($msg =~ /^:(\S+) UID (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (.*) (.*) :(.*)$/) {
		$user{$2}{'nick'} = $4;
	}
}

1;
