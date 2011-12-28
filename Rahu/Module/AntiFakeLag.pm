package Rahu::Module::AntiFakeLag;

use Rahu::Conf qw(rahu);
use Rahu::Util qw(ircsend addhandler);
use DBI;
use Cwd;

my $dbh = DBI->connect("dbi:SQLite:dbname=".getcwd()."/antifakelag.db","","");
addhandler("CONNECT", "Rahu::Module::AntiFakeLag::lookup");
addhandler("PRIVMSG", "Rahu::Module::AntiFakeLag::privmsg");

sub lookup {
	my ($botnick,$nick,$ident,$host) = @_;
	my $query = $dbh->prepare("SELECT fullhost FROM users WHERE active = 1");
	$query->execute();
	while (my ($fullhost) = $query->fetchrow_array) {
		if ("$nick\!$ident\@$host" =~ /^$fullhost$/) {
			ircsend(":$botnick PRIVMSG #diagnostics :$nick matches an antifakelag entry.");
			ircsend("SVS2NOLAG + $nick");
		}
	}

}

sub privmsg {
	my ($botnick, $src, $tgt, $msg) = @_;
	if ($tgt eq rahu_conf_botnick) {
		if ($msg =~ /^nofakelag add (.+)$/) {
			my $host = $1;
			my $orighost = $host;
			$host =~ s/\*/\.\*/g;
			my $query = $dbh->prepare("INSERT INTO users(fullhost, active) VALUES (?, 1)");
			$query->execute($host);
			ircsend(":$botnick NOTICE $src :Added $orighost to the no fakelag service");
		}
		if ($msg =~ /^nofakelag list$/) {
			my $query = $dbh->prepare("SELECT * FROM users");
			$query->execute();
			while (my ($id, $fullhost, $active) = $query->fetchrow_array) {
				ircsend(":$botnick NOTICE $src :$id -- $fullhost -- $active");
			}
		}
	}
}

1;
