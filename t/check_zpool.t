#!/usr/bin/perl
BEGIN {
    (my $srcdir = $0) =~ s,/[^/]+$,/,;
    unshift @INC, $srcdir;
}

use strict;
use warnings;
use Test::More tests => 63;
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
        message => 'pool:ONLINE pool:raidz1-0:ONLINE pool:raidz1-0:c0t1d0:ONLINE pool:raidz1-0:c0t4d0:ONLINE pool:raidz1-0:c0t7d0:ONLINE pool:raidz1-0:c1t2d0:ONLINE pool:raidz1-0:c1t5d0:ONLINE pool:raidz1-0:c3t1d0:ONLINE pool:raidz1-0:c3t4d0:(repairing) pool:raidz1-0:c3t7d0:ONLINE pool:raidz1-0:c4t3d0:ONLINE pool:raidz1-0:c4t6d0:ONLINE pool:raidz1-0:c5t1d0:ONLINE pool:raidz1-0:c5t4d0:ONLINE pool:raidz1-0:c5t7d0:ONLINE pool:raidz1-0:c6t2d0:ONLINE pool:raidz1-0:c6t5d0:ONLINE pool:raidz1-0:c0t2d0:ONLINE pool:raidz1-0:c0t5d0:ONLINE pool:raidz1-0:c1t0d0:ONLINE pool:raidz1-0:c1t3d0:ONLINE pool:raidz1-0:c1t6d0:ONLINE pool:raidz1-0:c3t2d0:ONLINE pool:raidz1-0:c3t5d0:ONLINE pool:raidz1-0:c4t1d0:ONLINE pool:raidz1-0:c4t4d0:ONLINE pool:raidz1-0:c4t7d0:(repairing) pool:raidz1-0:c5t2d0:ONLINE pool:raidz1-0:c5t5d0:ONLINE pool:raidz1-0:c6t0d0:ONLINE pool:raidz1-0:c6t3d0:ONLINE pool:raidz1-0:c6t6d0:ONLINE pool:raidz1-0:c0t3d0:ONLINE pool:raidz1-0:c0t6d0:ONLINE pool:raidz1-0:c1t1d0:ONLINE pool:raidz1-0:c1t4d0:ONLINE pool:raidz1-0:c1t7d0:ONLINE pool:raidz1-0:c3t3d0:ONLINE pool:raidz1-0:c3t6d0s0:ONLINE pool:raidz1-0:c4t2d0:ONLINE pool:raidz1-0:c4t5d0:ONLINE pool:raidz1-0:c5t0d0:ONLINE pool:raidz1-0:c5t3d0:ONLINE pool:raidz1-0:c5t6d0:ONLINE pool:raidz1-0:c6t1d0:ONLINE pool:raidz1-0:c6t4d0:ONLINE pool:raidz1-0:c6t7d0:ONLINE pool:spare:c3t0d0:AVAIL pool:spare:c0t0d0:AVAIL',
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
    { input => 'test3/zpool-status-faulted', status => CRITICAL,
        active => 1,
        message => 'boot-pool:ONLINE boot-pool:sdf3:ONLINE data:DEGRADED data:raidz2-0:DEGRADED data:raidz2-0:3fc9fe4f-dabc-497e-84fb-e76e9c2dd47a:ONLINE data:raidz2-0:e5872ecc-47be-4578-922c-79f2cc0e47ee:ONLINE data:raidz2-0:ad9c7a5b-44f4-43cb-99db-af04570e4aec:ONLINE data:raidz2-0:94a22a9d-da15-4928-adfa-d1ba637f2995:ONLINE data:raidz2-0:aa5ab8a7-4b03-4b90-a839-30cb1d2372fa:ONLINE data:raidz2-0:e9648cb7-5d5b-4786-b4b2-6d79204dbbaf:ONLINE data:raidz2-0:5d8586d0-4656-49f7-831e-461ca5dba49a:ONLINE data:raidz2-0:27bc4031-7570-4af8-9176-e75fa970fc3a:ONLINE data:raidz2-0:82461e40-f85d-468b-b6d1-1c5531c5c500:ONLINE data:raidz2-0:eef14afd-3141-4be2-b001-77d14f20b18a:ONLINE data:raidz2-0:54b59c9e-644c-4a70-bf3d-0033734b26ba:ONLINE data:raidz2-0:11f96b29-09c0-42e9-be43-2e31e9a60c9c:ONLINE data:raidz2-0:c1a450cf-096d-4e9c-b648-52cf07756b8d:ONLINE data:raidz2-0:19b41e01-32a2-4bfa-9f91-0fae3bd36980:ONLINE data:raidz2-0:896d54a6-62b0-41e9-80da-f1a8e8b95bc5:FAULTED data:raidz2-0:112fc120-3c39-4805-a1cb-65bfc44393b6:ONLINE data:raidz2-0:e8d3a7c4-c05c-4d1d-aa5b-7aeb34131dca:ONLINE data:raidz2-0:b40aee7b-bcb8-4715-850a-a277a5375755:ONLINE data:raidz2-0:343d8876-77f0-4a34-a29f-66d3b82487e9:ONLINE data:raidz2-0:733aca0b-4992-438a-92ff-76ae3efedec5:ONLINE data:raidz2-0:06e960da-0e2e-463c-a588-807440212a99:ONLINE data:raidz2-0:ea1a3a71-bc3e-47db-86fc-0dbd2adfc871:ONLINE data:raidz2-0:bcdb93f3-d1d6-491c-8271-65805a0c410f:ONLINE data:raidz2-0:b3cbda20-d787-4180-a823-b527f9a491bd:ONLINE data:raidz2-0:86f48bab-d5e9-4e3e-8c7f-6aae95e73991:ONLINE data:raidz2-0:def04eb1-063b-481a-a095-7bfd69cfe9e1:ONLINE',
    },
    { input => 'test3/zpool-status-double-resilvering', status => WARNING,
        active => 1,
        message => 'boot-pool:ONLINE boot-pool:sdz3:ONLINE data:DEGRADED data:raidz2-0:DEGRADED data:raidz2-0:3fc9fe4f-dabc-497e-84fb-e76e9c2dd47a:ONLINE data:raidz2-0:e5872ecc-47be-4578-922c-79f2cc0e47ee:ONLINE data:raidz2-0:replacing-2:DEGRADED data:raidz2-0:replacing-2:ad9c7a5b-44f4-43cb-99db-af04570e4aec:OFFLINE data:raidz2-0:replacing-2:02eced07-c4c9-4194-b198-a7d56059b059:(resilvering) data:raidz2-0:94a22a9d-da15-4928-adfa-d1ba637f2995:ONLINE data:raidz2-0:aa5ab8a7-4b03-4b90-a839-30cb1d2372fa:ONLINE data:raidz2-0:e9648cb7-5d5b-4786-b4b2-6d79204dbbaf:ONLINE data:raidz2-0:5d8586d0-4656-49f7-831e-461ca5dba49a:ONLINE data:raidz2-0:27bc4031-7570-4af8-9176-e75fa970fc3a:ONLINE data:raidz2-0:82461e40-f85d-468b-b6d1-1c5531c5c500:ONLINE data:raidz2-0:eef14afd-3141-4be2-b001-77d14f20b18a:ONLINE data:raidz2-0:54b59c9e-644c-4a70-bf3d-0033734b26ba:ONLINE data:raidz2-0:11f96b29-09c0-42e9-be43-2e31e9a60c9c:ONLINE data:raidz2-0:c1a450cf-096d-4e9c-b648-52cf07756b8d:ONLINE data:raidz2-0:19b41e01-32a2-4bfa-9f91-0fae3bd36980:ONLINE data:raidz2-0:replacing-14:DEGRADED data:raidz2-0:replacing-14:896d54a6-62b0-41e9-80da-f1a8e8b95bc5:OFFLINE data:raidz2-0:replacing-14:286c11c3-a3a1-4cef-9b29-bb958d574aca:(resilvering) data:raidz2-0:112fc120-3c39-4805-a1cb-65bfc44393b6:ONLINE data:raidz2-0:e8d3a7c4-c05c-4d1d-aa5b-7aeb34131dca:ONLINE data:raidz2-0:b40aee7b-bcb8-4715-850a-a277a5375755:ONLINE data:raidz2-0:343d8876-77f0-4a34-a29f-66d3b82487e9:ONLINE data:raidz2-0:733aca0b-4992-438a-92ff-76ae3efedec5:ONLINE data:raidz2-0:06e960da-0e2e-463c-a588-807440212a99:ONLINE data:raidz2-0:ea1a3a71-bc3e-47db-86fc-0dbd2adfc871:ONLINE data:raidz2-0:bcdb93f3-d1d6-491c-8271-65805a0c410f:ONLINE data:raidz2-0:b3cbda20-d787-4180-a823-b527f9a491bd:ONLINE data:raidz2-0:86f48bab-d5e9-4e3e-8c7f-6aae95e73991:ONLINE data:raidz2-0:def04eb1-063b-481a-a095-7bfd69cfe9e1:ONLINE',
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
