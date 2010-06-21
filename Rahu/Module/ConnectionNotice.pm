package Rahu::Module::ConnectionNotice;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);

addhandler("CONNECT", "Rahu::Module::ConnectionNotice::connnotice");

sub connnotice {
	my ($botnick, $target, $ident, $host, $gecos, $src) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :New client: $target ($ident\@$host) $gecos @ $src");
}

1;
