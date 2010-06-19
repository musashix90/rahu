package Rahu::Conf;

use strict;

my $prefix = $main::prefix;

sub import {
	my ($pkg, @files) = @_;
	foreach my $file (@files) {
		read_conf(caller(), $file);
	}
}

sub read_conf {
	no strict 'refs';
	my ($pkg, $caller, $extra, $file) = @_;
	open FH, $prefix.$file.".conf";
	while (my $line = <FH>) {
		next if $line =~ /^#/ || $line =~ /^\s/;
		$line =~ s/[\r\n]//g;
		my ($item,$data) = split(/\s?\=\s?/, $line,2);

		*{"${pkg}\::${file}_conf_${item}"} = sub { return $data };
	}
	close FH;
}

1;
