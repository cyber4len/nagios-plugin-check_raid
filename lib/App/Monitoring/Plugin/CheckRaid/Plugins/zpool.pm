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
    my ($p,$d,$sd,$s,$r);
    my $lp = '';
    my @status;
    my $spares = 0;
    my $output = $this->get_pools;

    foreach (@$output) {
        if (/^(\s+)([A-Z]+)\s+([A-Z+])/) {
            $lp = $1;
            next;
        }

        if (/^$lp([a-z0-9-]+)\s+([A-Z]+)/) {
            #Pool Status
            $p = $1; $d = ''; $sd = ''; $s = $2;
            push (@status, "$p:$s");
            #$this->critical unless ($s =~ /ONLINE/ );
            next;
        }

        $spares = 1 if (/spares/);

        if (/^$lp\s{2,6}([a-z0-9]+)\s+([A-Z]+).*\s+(\(repairing\)|\(resilvering\))?/) {
            #Subdevice Status - these can be attached to a device or a pool
            $sd = $1; $s = $2;
            $s = $3 if ($3);
            $r = '' if (/^$lp\s{2,4}[a-z0-9]+/);
            if ($s =~ /ONLINE/) {
                # no worries...
            } elsif ($spares) {
               $this->spare;
               $this->warning if ($s !~ /AVAIL/ );
            } elsif ($s =~ /repair|resilver/) {
                $this->resync;
            } else {
                $this->critical if ($r eq '');
            }
            if ($d eq '') {
                push(@status, "$p:$sd:$s");
            } elsif  ($spares) {
                $this->spare;
                push(@status, "spare:$sd:$s");
            } else {
                if ($r eq '') {
                    push(@status, "$p:$d:$sd:$s");
                } else {
                    push(@status, "$p:$d:$r:$sd:$s");
                }
            }
            next;
        }
        if (/^$lp\s{2}([a-z0-9-]+)\s+([A-Z]+)/) {
            #Device Status
            $d = $1; $s = $2; $r = '';
            push (@status, "$p:$d:$s");
            $this->critical unless ($s =~ /ONLINE/ || $spares == 1 || $r eq '');
            next;
        }
        if (/^$lp\s{4}([a-z0-9-]+)\s+([A-Z]+)/) {
            #Replacing Status
            $r = $1; $s = $2;
            push (@status, "$p:$d:$r:$s");
            next;
        }

    }
    return unless @status;
    $this->ok;
    $this->message(join(' ', @status));
}

1;
