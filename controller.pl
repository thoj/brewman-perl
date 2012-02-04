#/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use Time::HiRes qw(sleep);
use Data::Dumper;
my $Kp = 6;
my $Kd = 5;
my $Ki = 1;

my $deadband    = 5;

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

while ( sleep 2 ) {
    $pv = read_pv();
    $sp = read_sp();
    my $output = pid( $pid_par, $pv, $sp );
    if ( $output > 50 && $output - 50 > $deadband ) {
        up_pulse();
    }
    elsif ( $output < 50 && $output - 50 < -$deadband ) {
        down_pulse();
    }
    else {
        print "Nop.\n";
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
    foreach my $k ( keys $sensors ) {
        my $fh;
        open( $fh, "$owfs/$k/temperature" );
        my $temp = <$fh>;
        $total += $temp;
        close($fh);
    }
    return $total / scalar keys $sensors;
}

sub up_pulse {
    my $sock = new IO::Socket::INET(
        PeerAddr => 'localhost',
        PeerPort => '9999',
        Proto    => 'tcp',
    );
    die "Could not create socket: $!\n" unless $sock;
    print $sock "~out8=1~";
    sleep(0.1);
    print $sock "~out8=0~";
    close($sock);
}

sub down_pulse {
    my $sock = new IO::Socket::INET(
        PeerAddr => 'localhost',
        PeerPort => '9999',
        Proto    => 'tcp',
    );
    die "Could not create socket: $!\n" unless $sock;
    print $sock "~out9=1~";
    sleep(0.1);
    print $sock "~out9=0~";
    close($sock);
}

