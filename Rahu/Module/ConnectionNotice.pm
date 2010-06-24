package Rahu::Module::ConnectionNotice;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);

addhandler("CONNECT", "Rahu::Module::ConnectionNotice::connnotice");
addhandler("NICK", "Rahu::Module::ConnectionNotice::nicknotice");
addhandler("QUIT", "Rahu::Module::ConnectionNotice::quitnotice");

sub connnotice {
	my ($botnick, $target, $ident, $host, $gecos, $src) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :New client: $target ($ident\@$host) $gecos @ $src");
}

sub nicknotice {
	my ($botnick, $oldnick, $newnick, $ident, $host, $gecos) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Nick change: $oldnick ($ident\@$host) => $newnick");
}

sub quitnotice {
	my ($botnick, $nick, $ident, $host, $gecos, $server, $msg) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Client quit: $nick ($ident\@$host) $gecos @ $server - $msg");
}

1;
