package Rahu::Module::CTCPVersion;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);

addhandler("CONNECT", "Rahu::Module::CTCPVersion::version");
addhandler("NOTICE", "Rahu::Module::CTCPVersion::recv_version");

sub version {
	my ($botnick,$target) = @_;
	ircsend(":$botnick PRIVMSG $target :\001VERSION\001");
}

sub recv_version {
	my ($botnick, $src, $tgt, $msg) = @_;
	if ($tgt eq rahu_conf_botnick) {
		if ($msg =~ /^\001VERSION (.*)\001$/) {
			ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :CTCP VERSION reply received from $src: $1");
		}
	}
}

1;
