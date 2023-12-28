#!/usr/bin/perl
BEGIN {
    (my $srcdir = $0) =~ s,/[^/]+$,/,;
    unshift @INC, $srcdir;
}

use strict;
use warnings;
use Test::More tests => 51;
use test;

my @tests = (
    { input => 'test1/zpool-status-no-pools', status => UNKNOWN,
        active => 0,
        message => 'no pools available',
    },
    { input => 'test1/zpool-status-good-1', status => OK,
        active => 1,
        message => 'rpool:ONLINE rpool:mirror-0:ONLINE rpool:mirror-0:c0t0d0s0:ONLINE rpool:mirror-0:c0t1d0s0:ONLINE upool:ONLINE upool:mirror-0:ONLINE upool:mirror-0:c0t2d0:ONLINE upool:mirror-0:c0t3d0:ONLINE',
    },
    { input => 'test1/zpool-status-good-2', status => OK,
        active => 1,
        message => 'zpool-mds01-intermail-app:ONLINE zpool-mds01-intermail-app:c4t7d0:ONLINE zpool-mds01-intermail-app-logs:ONLINE zpool-mds01-intermail-app-logs:c4t9d0:ONLINE zpool-mds01-oracle-app:ONLINE zpool-mds01-oracle-app:c4t6d0:ONLINE zpool-mds01-oracle-archive-logs:ONLINE zpool-mds01-oracle-archive-logs:c4t3d0:ONLINE zpool-mds01-oracle-backups:ONLINE zpool-mds01-oracle-backups:c4t5d0:ONLINE zpool-mds01-oracle-indices:ONLINE zpool-mds01-oracle-indices:c4t2d0:ONLINE zpool-mds01-oracle-redo-logs:ONLINE zpool-mds01-oracle-redo-logs:c4t4d0:ONLINE zpool-mds01-oracle-tablespaces:ONLINE zpool-mds01-oracle-tablespaces:c4t0d0:ONLINE zpool-mds01-sleepycat-db:ONLINE zpool-mds01-sleepycat-db:c4t8d0:ONLINE',
    },
    { input => 'test1/zpool-status-repairing', status => WARNING,
        active => 1,
        message => 'pool:ONLINE pool:raidz1-0:ONLINE pool:raidz1-0:c0t1d0:ONLINE pool:raidz1-0:c0t4d0:ONLINE pool:raidz1-0:c0t7d0:ONLINE pool:raidz1-0:c1t2d0:ONLINE pool:raidz1-0:c1t5d0:ONLINE pool:raidz1-0:c3t1d0:ONLINE pool:raidz1-0:c3t4d0:(repairing) pool:raidz1-0:c3t7d0:ONLINE pool:raidz1-0:c4t3d0:ONLINE pool:raidz1-0:c4t6d0:ONLINE pool:raidz1-0:c5t1d0:ONLINE pool:raidz1-0:c5t4d0:ONLINE pool:raidz1-0:c5t7d0:ONLINE pool:raidz1-0:c6t2d0:ONLINE pool:raidz1-0:c6t5d0:ONLINE pool:raidz1-0:c0t2d0:ONLINE pool:raidz1-0:c0t5d0:ONLINE pool:raidz1-0:c1t0d0:ONLINE pool:raidz1-0:c1t3d0:ONLINE pool:raidz1-0:c1t6d0:ONLINE pool:raidz1-0:c3t2d0:ONLINE pool:raidz1-0:c3t5d0:ONLINE pool:raidz1-0:c4t1d0:ONLINE pool:raidz1-0:c4t4d0:ONLINE pool:raidz1-0:c4t7d0:(repairing) pool:raidz1-0:c5t2d0:ONLINE pool:raidz1-0:c5t5d0:ONLINE pool:raidz1-0:c6t0d0:ONLINE pool:raidz1-0:c6t3d0:ONLINE pool:raidz1-0:c6t6d0:ONLINE pool:raidz1-0:c0t3d0:ONLINE pool:raidz1-0:c0t6d0:ONLINE pool:raidz1-0:c1t1d0:ONLINE pool:raidz1-0:c1t4d0:ONLINE pool:raidz1-0:c1t7d0:ONLINE pool:raidz1-0:c3t3d0:ONLINE pool:raidz1-0:c3t6d0s0:ONLINE pool:raidz1-0:c4t2d0:ONLINE pool:raidz1-0:c4t5d0:ONLINE pool:raidz1-0:c5t0d0:ONLINE pool:raidz1-0:c5t3d0:ONLINE pool:raidz1-0:c5t6d0:ONLINE pool:raidz1-0:c6t1d0:ONLINE pool:raidz1-0:c6t4d0:ONLINE pool:raidz1-0:c6t7d0:ONLINE pool:c3t0d0:AVAIL pool:c0t0d0:AVAIL',
    },
    { input => 'test2/zpool-status-good', status => OK,
        active => 1,
        message => 'main:ONLINE main:raidz2-0:ONLINE main:raidz2-0:sda:ONLINE main:raidz2-0:sdb:ONLINE main:raidz2-0:sdc:ONLINE main:raidz2-0:sdd:ONLINE main:raidz2-0:sde:ONLINE main:raidz2-0:sdf:ONLINE main:raidz2-0:sdg:ONLINE main:raidz2-0:sdh:ONLINE main:raidz2-0:sdi:ONLINE main:raidz2-0:sdj:ONLINE main:raidz2-0:sdk:ONLINE main:raidz2-0:sdl:ONLINE main:raidz2-0:sdm:ONLINE main:raidz2-1:ONLINE main:raidz2-1:sdn:ONLINE main:raidz2-1:sdo:ONLINE main:raidz2-1:sdp:ONLINE main:raidz2-1:sdq:ONLINE main:raidz2-1:sdr:ONLINE main:raidz2-1:sds:ONLINE main:raidz2-1:sdt:ONLINE main:raidz2-1:sdu:ONLINE main:raidz2-1:sdv:ONLINE main:raidz2-1:sdw:ONLINE main:raidz2-1:sdx:ONLINE main:raidz2-1:sdy:ONLINE main:raidz2-1:sdz:ONLINE',
    },
    { input => 'test2/zpool-status-faulted', status => CRITICAL,
        active => 1,
        message => 'main:DEGRADED main:raidz2-0:ONLINE main:raidz2-0:sda:ONLINE main:raidz2-0:sdb:ONLINE main:raidz2-0:sdc:ONLINE main:raidz2-0:sdd:ONLINE main:raidz2-0:sde:ONLINE main:raidz2-0:sdf:ONLINE main:raidz2-0:sdg:ONLINE main:raidz2-0:sdh:ONLINE main:raidz2-0:sdi:ONLINE main:raidz2-0:sdj:ONLINE main:raidz2-0:sdk:ONLINE main:raidz2-0:sdl:ONLINE main:raidz2-0:sdm:ONLINE main:raidz2-1:DEGRADED main:raidz2-1:sdn:FAULTED main:raidz2-1:sdo:ONLINE main:raidz2-1:sdp:ONLINE main:raidz2-1:sdq:ONLINE main:raidz2-1:sdr:ONLINE main:raidz2-1:sds:ONLINE main:raidz2-1:sdt:ONLINE main:raidz2-1:sdu:ONLINE main:raidz2-1:sdv:ONLINE main:raidz2-1:sdw:ONLINE main:raidz2-1:sdx:ONLINE main:raidz2-1:sdy:ONLINE main:raidz2-1:sdz:ONLINE',
    },
    { input => 'test2/zpool-status-unavailable', status => CRITICAL,
        active => 1,
        message => 'main:DEGRADED main:raidz2-0:DEGRADED main:raidz2-0:sda:ONLINE main:raidz2-0:sdb:UNAVAIL main:raidz2-0:sdc:ONLINE main:raidz2-0:sdd:ONLINE main:raidz2-0:sde:ONLINE main:raidz2-0:sdf:ONLINE main:raidz2-0:sdg:ONLINE main:raidz2-0:sdh:ONLINE main:raidz2-0:sdi:ONLINE main:raidz2-0:sdj:ONLINE main:raidz2-0:sdk:ONLINE main:raidz2-0:sdl:ONLINE main:raidz2-0:sdm:ONLINE main:raidz2-1:ONLINE main:raidz2-1:sdn:ONLINE main:raidz2-1:sdo:ONLINE main:raidz2-1:sdp:ONLINE main:raidz2-1:sdq:ONLINE main:raidz2-1:sdr:ONLINE main:raidz2-1:sds:ONLINE main:raidz2-1:sdt:ONLINE main:raidz2-1:sdu:ONLINE main:raidz2-1:sdv:ONLINE main:raidz2-1:sdw:ONLINE main:raidz2-1:sdx:ONLINE main:raidz2-1:sdy:ONLINE main:raidz2-1:sdz:ONLINE',
    },
    { input => 'test2/zpool-status-replacing-resilvering', status => WARNING,
        active => 1,
        message => 'main:DEGRADED main:raidz2-0:ONLINE main:raidz2-0:sda:ONLINE main:raidz2-0:sdb:ONLINE main:raidz2-0:sdc:ONLINE main:raidz2-0:sdd:ONLINE main:raidz2-0:sde:ONLINE main:raidz2-0:sdf:ONLINE main:raidz2-0:sdg:ONLINE main:raidz2-0:sdh:ONLINE main:raidz2-0:sdi:ONLINE main:raidz2-0:sdj:ONLINE main:raidz2-0:sdk:ONLINE main:raidz2-0:sdl:ONLINE main:raidz2-0:sdm:ONLINE main:raidz2-1:DEGRADED main:raidz2-1:replacing-0:DEGRADED main:raidz2-1:replacing-0:old:FAULTED main:raidz2-1:replacing-0:sdn:(resilvering) main:raidz2-1:sdo:ONLINE main:raidz2-1:sdp:ONLINE main:raidz2-1:sdq:ONLINE main:raidz2-1:sdr:ONLINE main:raidz2-1:sds:ONLINE main:raidz2-1:sdt:ONLINE main:raidz2-1:sdu:ONLINE main:raidz2-1:sdv:ONLINE main:raidz2-1:sdw:ONLINE main:raidz2-1:sdx:ONLINE main:raidz2-1:sdy:ONLINE main:raidz2-1:sdz:ONLINE',
    },
    { input => 'test2/zpool-status-resilvering', status => WARNING,
        active => 1,
        message => 'main:ONLINE main:raidz2-0:ONLINE main:raidz2-0:sda:(resilvering) main:raidz2-0:sdb:ONLINE main:raidz2-0:sdc:ONLINE main:raidz2-0:sdd:ONLINE main:raidz2-0:sde:ONLINE main:raidz2-0:sdf:ONLINE main:raidz2-0:sdg:ONLINE main:raidz2-0:sdh:ONLINE main:raidz2-0:sdi:ONLINE main:raidz2-0:sdj:ONLINE main:raidz2-0:sdk:ONLINE main:raidz2-0:sdl:ONLINE main:raidz2-0:sdm:ONLINE main:raidz2-1:ONLINE main:raidz2-1:sdn:ONLINE main:raidz2-1:sdo:ONLINE main:raidz2-1:sdp:ONLINE main:raidz2-1:sdq:ONLINE main:raidz2-1:sdr:ONLINE main:raidz2-1:sds:ONLINE main:raidz2-1:sdt:ONLINE main:raidz2-1:sdu:ONLINE main:raidz2-1:sdv:ONLINE main:raidz2-1:sdw:ONLINE main:raidz2-1:sdx:(resilvering) main:raidz2-1:sdy:ONLINE main:raidz2-1:sdz:ONLINE',
    },
);

# test that plugin can be created
ok(zpool->new, "plugin created");

foreach my $test (@tests) {
    my $plugin = zpool->new(
        program => '/bin/true',
        commands => {
            'zpool' => ['<', TESTDIR . '/data/zpool/' . $test->{input}],
        },
    );
    ok($plugin, "plugin created: $test->{input}");

    my $active = $plugin->active;
    ok($active == $test->{active}, "active matches");

    # can't check if plugin not active
    next unless $active;

    $plugin->check;
    ok(1, "check ran");

    ok(defined($plugin->status), "status code set");
    is($plugin->status, $test->{status}, "status code matches");
    is($plugin->message, $test->{message}, "status message");
}
