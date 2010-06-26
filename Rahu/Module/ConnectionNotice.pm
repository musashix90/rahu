package Rahu::Module::ConnectionNotice;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);

addhandler("CHGHOST", "Rahu::Module::ConnectionNotice::chghostnotice");
addhandler("CHGIDENT", "Rahu::Module::ConnectionNotice::chgidentnotice");
addhandler("CONNECT", "Rahu::Module::ConnectionNotice::connnotice");
addhandler("NICK", "Rahu::Module::ConnectionNotice::nicknotice");
addhandler("QUIT", "Rahu::Module::ConnectionNotice::quitnotice");
addhandler("SETHOST", "Rahu::Module::ConnectionNotice::sethostnotice");
addhandler("SETIDENT", "Rahu::Module::ConnectionNotice::setidentnotice");

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

sub chghostnotice {
	my ($botnick, $srcnick, $tgtnick, $ident, $host, $virthost) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Host change: $tgtnick ($ident\@$host => $ident\@$virthost) by $srcnick");
}

sub sethostnotice {
	my ($botnick, $srcnick, $ident, $host, $virthost) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Host change: $srcnick ($ident\@$host => $ident\@$virthost)");
}

sub chgidentnotice {
	my ($botnick, $srcnick, $tgtnick, $ident, $host, $newident) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Ident change: $tgtnick ($ident\@$host => $newident\@$host) by $srcnick");
}

sub setidentnotice {
	my ($botnick, $srcnick, $ident, $host, $newident) = @_;
	ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :Ident change: $srcnick ($ident\@$host => $newident\@$host)");
}

1;
