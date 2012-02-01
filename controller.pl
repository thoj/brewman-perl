#/usr/bin/perl
use strict;
use warnings;


my $Kp = 0.4;
my $Kd = 0.01;
my $Ki = 0.1;

my $output = 50;
my $output_max = 100;
my $output_min = 0;

my $deadband = 5;
my $last_output = 50;


my $pv_last = read_pv();
my $sp = read_sp();

my $pv = 0;
my $iterm = 0;

# period is 60 seconds.

while (sleep 6) {
	$pv = read_pv();	

	# Calculate integral.
	my $error = $sp - $pv;
	$iterm += ($Ki * $error);
	# Limit integral
	if ($iterm > $output_max) {$output = $output_max; }
	if ($iterm < $output_min) {$output = $output_min; }
	
	# Calculate derivative	
	my $dterm = ($pv - $pv_last);

	# Calculate output
	$output = $Kp * $error + $iterm - $Kd * $dterm;
	
	# Limit output
	if ($output > $output_max) {$output = $output_max; }
	if ($output < $output_min) {$output = $output_min; }
	
	print "$output E: $error I: $iterm D: $dterm PV: $pv PV_Last: $pv_last\n";
	
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
	# Read SP from file?
	# Fake it for now
	return 55;
}

sub read_pv
{
	# Read PV from sensors
	# Fake it for now
	return $output*0.87;
}
