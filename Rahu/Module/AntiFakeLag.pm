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
			$fullhost =~ s/\\S\+/\*/g;
			ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :$nick\!$ident\@$host matches an antifakelag entry ($fullhost)");
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
			$host =~ s/\*/\\S\+/g;
			my $query = $dbh->prepare("INSERT INTO users(fullhost, active) VALUES (?, 1)");
			$query->execute($host);
			ircsend(":$botnick NOTICE $src :Added $orighost to the antifakelag service");
			ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :$src added $orighost to the antifakelag service");
		}
		elsif ($msg =~ /^nofakelag del (.+)$/) {
			my $host = $1;
			my $orighost = $host;
			$host =~ s/\*/\\S\+/g;
			my $query = $dbh->prepare("SELECT count(id) FROM users WHERE fullhost = ?");
			$query->execute($host);
			my $count = $query->fetchrow_array();
			if ($count > 0) {
				my $query = $dbh->prepare("DELETE FROM users WHERE fullhost = ?");
				$query->execute($host);
				ircsend(":$botnick NOTICE $src :Deleted $orighost from antifakelag service");
				ircsend(":$botnick PRIVMSG @{[rahu_conf_debugchan]} :$src deleted $orighost from antifakelag service");
			} else {
				ircsend(":$botnick NOTICE $src :No matches were found");
			}
		}
		elsif ($msg =~ /^nofakelag list$/) {
			ircsend(":$botnick NOTICE $src :Listing anti fakelag entries:");
			my $query = $dbh->prepare("SELECT * FROM users");
			$query->execute();
			while (my ($id, $fullhost, $active) = $query->fetchrow_array) {
				$fullhost =~ s/\\S\+/\*/g;
				ircsend(":$botnick NOTICE $src :  $fullhost");
			}
		}
	}
}

1;
