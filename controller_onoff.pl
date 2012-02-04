#/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use Time::HiRes qw(sleep gettimeofday tv_interval);
use Data::Dumper;

my $Kp = 0.1;
my $Kd = 0.4;
my $Ki = 0.05;

my $deadband = 0.5;

my $owfs    = "/mnt/owfs";
my $sensors = {};
my $dir;
opendir( $dir, $owfs ) || die "No OWFS found!";
while ( my $d = readdir $dir ) {
    if ( $d =~ m/^28\./xmi ) {
        $sensors->{$d} = {};
    }
}

my $pv = read_pv();
my $sp = read_sp();

my $pid_par = init_pid( $Kp, $Kd, $Ki, 0, 100, $pv );
$pid_par->{iterm} = $sp - $pv;    #feedforward

print Dumper($pid_par);

my $periode  = 10;
my $is_on    = 0;
my $on_time  = [gettimeofday()];
my $off_time = [gettimeofday()];
my $output   = 0;

my $pid_time = [gettimeofday()];
my $req_ontime = 0;

while ( sleep 0.1 ) {
    $pv = read_pv();
    $sp = read_sp();
    if ( tv_interval($pid_time) > 5 ) {
        $output = pid( $pid_par, $pv, $sp );
        $pid_time = [gettimeofday()];
    	$req_ontime = $periode * ( $output / 100 );
	#print "Req Ontime: $req_ontime\n";
    }
    if ( $output > 0 && $output < 100 ) {
        if ($is_on) {
            if ( tv_interval($on_time) > $req_ontime ) {
                pwm_off();
                $off_time = [gettimeofday()];
                $is_on    = 0;
            }
        }
        else {
            if ( tv_interval($off_time) > $periode - $req_ontime ) {
                pwm_on();
                $on_time = [gettimeofday()];
                $is_on   = 1;
            }
        }
    }
    elsif ( $output == 100 ) {
        pwm_on();
        $is_on = 1;

    }
    else {
        pwm_off();
        $is_on = 0;
    }
}

sub init_pid {
    my ( $Kp, $Kd, $Ki, $min, $max, $pv ) = @_;
    my $par = { kp => $Kp, kd => $Kd, ki => $Ki, max => $max, min => $min };
    $par->{iterm}  = 0;
    $par->{lastpv} = $pv;
    return $par;
}

sub pid {
    my ( $par, $pv, $sp ) = @_;

    # Calculate integral.
    my $error = $sp - $pv;
    $par->{iterm} += ( $par->{ki} * $error );

    # Limit integral
    if ( $par->{iterm} > $par->{max} ) { $par->{iterm} = $par->{max}; }
    if ( $par->{iterm} < $par->{min} ) { $par->{iterm} = $par->{min}; }

    # Calculate derivative
    my $dterm = $pv - $par->{lastpv};

    # Calculate output
    my $output = $par->{kp} * $error + $par->{iterm} - $par->{kd} * $dterm;

    # Limit output
    if ( $output > $par->{max} ) { $output = $par->{max}; }
    if ( $output < $par->{min} ) { $output = $par->{min}; }

    $par->{lastpv} = $pv;

    printf(
        "%.1f (PV: %.1f E: %.1f P: %.1f I: %.1f D: %.1f)\n",
        $output, $pv, $error, $par->{kp} * $error,
        $par->{iterm}, $dterm
    );

    return $output;
}

sub read_sp {
    return 67;
}

sub read_pv {
    my $total = 0;
    return 50 if scalar keys $sensors < 1;
    foreach my $k ( keys $sensors ) {
        my $fh;
        open( $fh, "$owfs/$k/temperature" );
        my $temp = <$fh>;
        $total += $temp;
        close($fh);
    }
    return $total / scalar keys $sensors;
}

sub pwm_on {
	#print "On\n";
}

sub pwm_off {
	#print "Off\n";
}

