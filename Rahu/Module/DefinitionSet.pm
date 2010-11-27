package Rahu::Module::DefinitionSet;

use LWP::UserAgent;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);

addhandler("PING", "Rahu::Module::DefinitionSet::get_definitions");

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

sub get_definitions {
	ircsend(":002AAAAAA PRIVMSG @{[rahu_conf_debugchan]} :Updating defitions.");
	my $response = $ua->get('http://mx90.net/ruleset.php');

	if ($response->is_success) {
		ircsend(":002AAAAAA PRIVMSG @{[rahu_conf_debugchan]} :Got definition set. ".$response->as_string);
	} else {
		ircsend(":002AAAAAA PRIVMSG @{[rahu_conf_debugchan]} :Downloading of definition set failed. ".$response->status_line);
	}
}

1;
