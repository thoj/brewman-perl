#!/bin/perl

use strict;
use warnings;

use CGI::Fast;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");
my $sth = $dbh->prepare("SELECT * FROM alias");
While ($c = CGI::Fast->new()) {
	my $res = $sth->execute();
	my $data = {};	
	while (my $row = $dbh->fetchrow_hashref($sth)) {
		$data->{$row->{id}}{alias} = $row->{alias};
	}
	foreach my $k (keys $data) {
		my $dqr = $dbh->prepare("SELECT UNIX_TIMESTAMP(`datetime`) as datetime, value FROM ".$k." WHERE `datetime` < ? LIMIT 100");
		if ( $dqr->execute($datequery) ) {
			$data->{$k}{data} = [];
			while (my $row = $dqr->fetchrow_hashref($sth)) {
				push @{$data->{$k}{data}}, { date => $row->{datetime}, value => $row->{value}};
			}
		}
	}
	print json_encode($data);
}
