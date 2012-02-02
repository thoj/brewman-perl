#/usr/bin/perl
use strict;
use warnings;


my $Kp = 2;
my $Kd = 4.5;
my $Ki = 0.1;

my $output = 50;
my $output_max = 100;
my $output_min = 0;

my $deadband = 5;
my $last_output = 50;

my $owfs = "/mnt/owfs";
my $sensors = {};
my $dir;
opendir($dir, $owfs) || die "No OWFS found!";
while (my $d = readdir $dir ) {
	if ($d =~ m/^28\./xmi) {
		$sensors->{$d} = {};
	}
}

my $pv_last = read_pv();
my $sp = read_sp();

my $pv = 0;
my $iterm = $pv-$sp;; #feedforward?

# period is 60 seconds.

while (sleep 6) {
	$pv = read_pv();	

	# Calculate integral.
	my $error = $sp - $pv;
	$iterm += ($Ki * $error);
	# Limit integral
	if ($iterm > $output_max) {$iterm = $output_max; }
	if ($iterm < $output_min) {$iterm = $output_min; }
	
	# Calculate derivative	
	my $dterm = ($pv - $pv_last);

	# Calculate output
	$output = $Kp * $error + $iterm - $Kd * $dterm;
	
	# Limit output
	if ($output > $output_max) {$output = $output_max; }
	if ($output < $output_min) {$output = $output_min; }
	
	printf("%.1f PV: %.1f E: %.1f I: %.1f D: %.1f PV_Last: %.1f?\n", $output, $pv, $error, $iterm, $dterm, $pv_last);
	
	$pv_last = $pv;
	
	# Here i need to deside if i need to inc my 3 pole controller 
	# or dec. Not sure of the best way to do this yet.
	
	if ($output > 50 && $output - 50 > $deadband) 
	{
		#Send increase pulse
		print "Inc.\n"
	} elsif ($output < 50 && $output - 50 < -$deadband) {
		#Send decrease pulse
		print "Dec.\n";
	} else {
		print "Nop.\n";
	}
	
}

sub read_sp {
	return 67;
}

sub read_pv
{
	my $total = 0;
	foreach my $k (keys $sensors) {
		my $fh;
		open($fh, "$owfs/$k/temperature");
		my $temp = <$fh>;
		$total += $temp;
		close($fh);
	}
	return $total / scalar keys $sensors;
}
