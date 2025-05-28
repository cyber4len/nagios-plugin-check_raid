package App::Monitoring::Plugin::CheckRaid::Plugins::zpool;

# Solaris/Linux, software RAID via ZFS
# code taken from: https://github.com/noblemtw/nagios-plugin-check_raid/

use base 'App::Monitoring::Plugin::CheckRaid::Plugin';
use strict;
use warnings;

sub program_names {
    shift->{name};
}


sub commands {
    {
        'zpool' => ['>&2', '@CMD', 'status'],
    }
}

sub active {
    my ($this) = @_;

    # program not found
    return 0 unless $this->{program};

    my @pools = $this->get_pools;
    return $#pools >= 0;

}

sub get_pools {
    my $this = shift;

    # cache inside single run
    return $this->{output} if defined $this->{output};

    my $fh = $this->cmd('zpool');
    my @data;
    while (<$fh>) {
        chomp;
        return if /no pools available|The ZFS modules are not loaded/;
        $_ =~ s/\t/        /g;
        push(@data, $_);
    }

    return $this->{output} = \@data;
}

sub check {
    my $this = shift;
    my ($p,$d,$sd,$s,$r,$ls);
    my $lp = '';
    my @status;
    my $spares = 0;
    my $output = $this->get_pools;

    foreach (@$output) {
        if (/^(\s+)([A-Z]+)\s+([A-Z+])/) { # Find pool header
            $lp = $1; # initialize length of whitespaces
            next; # go to next line
        }

        if (/^$lp([a-z0-9-]+)\s+([A-Z]+)/) { # Find pool name and status
            #Pool Status
            $p = $1; $d = ''; $sd = ''; $s = $2; $r = ''; $spares = 0; $ls = ''; # initialize pool and status, null other elements
            push (@status, "$p:$s");
            $this->warning if ($s =~ /DEGRADED/ ); # warning if pool degraded
            next;
        }

        if (/spares/) {
            $spares = 1;
            $p = "$p:spare"; # add "spare" to pool name
        }

        if (/^$lp(\s{2,6})([a-z0-9-]+)\s+([A-Z]+)(.*\s+)?(\(repairing\)|\(resilvering\))?/) { # Find all devices and subdevices
            #Subdevice Status - these can be attached to a device or a pool, or a spare
            $s = $3;
            $s = $5 if ($5); # get status from last column if present
            $r = '';
            if (length($1) == 2) {
                $d = $2; $sd = '';
                push(@status, "$p:$d:$s");
            } elsif (length($1) == 4) {
                $sd = $2;
                push(@status, "$p:$d:$sd:$s");
            } else {
                $r = $2;
                push(@status, "$p:$d:$sd:$r:$s");
            }
            if ($s =~ /ONLINE/) {
                # no worries...
            } elsif ($s =~ /DEGRADED/) {
                $this->warning;
            } elsif ($spares) {
               $this->spare;
               $this->warning if ($s !~ /AVAIL/ );
            } elsif ($s =~ /repair|resilver/) {
                $this->resync;
            } else {
                $this->critical unless ($d =~ /replacing/ || $sd =~ /replacing/ || $r);
            }
        }
    }
    return unless @status;
    $this->ok;
    $this->message(join(' ', @status));
}

1;
