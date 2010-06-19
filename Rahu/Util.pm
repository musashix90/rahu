package Rahu::Util;

use strict;
use Exporter 'import';
use Cwd qw(getcwd);
BEGIN {
	our @EXPORT = qw(find_protocol ircsend);
}

sub find_protocol {
	my ($protocol) = @_;
	opendir (DIR, main::PREFIX."/Rahu/Protocol/") or die("Error opening ".main::PREFIX."/Rahu/Protocol/");
	while ((my $file = readdir(DIR))) {
		if (lc $file =~ /^${protocol}\.pm$/i) {
			return $file;
		}
	}
	closedir(DIR);
}

sub ircsend {
	my ($msg) = @_;
	print $main::sock $msg."\n";
	print "> $msg\n";
}

1;
