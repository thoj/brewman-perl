#!/usr/bin/perl
# 
# Thomas Jäger 2012
#
use strict;
use warnings;

use DBI;
use Data::Dumper;

my $dbfile = "data_log.db";
my $owfs = "/home/tj/owfs";

my $sensors = {};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

$dbh->do("CREATE TABLE alias( id STRING, alias STRING )");

my $dir;
opendir($dir, $owfs) || die "No OWFS found!";
print "Reading Sensors\n";
while (my $d = readdir $dir ) {
	if ($d =~ m/^28\./xmi) {
		$sensors->{$d} = {};
		$dbh->do("CREATE TABLE `$d`( id INTEGER PRIMARY KEY, datetime DATETIME, value REAL)");
	}
}
if (scalar keys $sensors < 1) {
	die "No sensors found!";
}
print "Logging ".( scalar keys $sensors) . " sensors.";
close($dir);
foreach my $k (keys $sensors) {
	$sensors->{$k}{sth} = $dbh->prepare("INSERT INTO `$k` (datetime,value) VALUES(DATETIME('now'),?)");
}
while (sleep 5) {
	foreach my $k (keys $sensors) {
		my $fh;
		open($fh, "$owfs/$k/temperature");
		my $temp = <$fh>;
		close($fh);
		$sensors->{$k}{sth}->execute($temp);
	}
}
