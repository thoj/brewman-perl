#/usr/bin/perl

my $Kp = 0.1;
my $Kd = 4;
my $Ki = 0.2;

my $output = 0;

my $output_max = 100;
my $output_min = 0;

my $last_pv = 51;

my $pv = 50;
my $sp = 55;

my $iterm = 0;

while (sleep 2) {
	#Read PV and SP
	print "PV $pv ";
	
	# Calculate integral.
	my $error = $sp - $pv;
	$iterm += ($Ki * $error);
#	print "Iterm: $iterm\n";
	if ($iterm > $output_max) {$output = $output_max; }
	if ($iterm < $output_min) {$output = $output_min; }
	
	my $dterm = ($pv - $pv_last);

	$output = ($Kp * $error) + $iterm - $Kd * $dterm;
	print "$output ";
	
	if ($output > $output_max) {$output = $output_max; }
	if ($output < $output_min) {$output = $output_min; }
	
	print " Output: $output\n";
	
	$pv = 100 * ($output / 100);
	$pv_last = $pv;
	
}
