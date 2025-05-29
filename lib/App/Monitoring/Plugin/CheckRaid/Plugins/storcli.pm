package App::Monitoring::Plugin::CheckRaid::Plugins::storcli;

# MegaRAID SAS 39xx controllers
# based on megacli.pm and inspired by the following plugin:
# https://github.com/thomas-krenn/check_lsi_raid
# all copyrights reserved

use base 'App::Monitoring::Plugin::CheckRaid::Plugin';
use strict;
use warnings;

sub program_names {
	qw(storcli64 storcli);
}

sub commands {
	{
		'pdlist' => ['-|', '@CMD', '/call/eall/sall', 'show', 'all', 'nolog'],
#TODO		'pdinit' => ['-|', '@CMD', '/call/eall/sall', 'show', 'initialization', 'nolog'],
#TODO		'pdrebuild' => ['-|', '@CMD', '/call/eall/sall', 'show', 'rebuild', 'nolog'],
		'ldinfo' => ['-|', '@CMD', '/call/vall', 'show', 'all', 'nolog'],
#TODO		'ldinit' => ['-|', '@CMD', '/call/vall', 'show', 'init', 'nolog'],
		'batterywarning' => ['-|', '@CMD', '/call', 'show', 'batterywarning', 'nolog'],
		'battery' => ['-|', '@CMD', '/call/bbu', 'show', 'status', 'nolog'],
		'cachevault' => ['-|', '@CMD', '/call/cv', 'show', 'status', 'nolog'],
	}
}

sub sudo {
	my ($this, $deep) = @_;
	# quick check when running check
	return 1 unless $deep;

	my $cmd = $this->{program};

	(
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/eall/sall show all nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/eall/sall show initialization nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/eall/sall show rebuild nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/vall show all nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/vall show init nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call show batterywarning nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/bbu show status nolog",
                "CHECK_RAID ALL=(root) NOPASSWD: $cmd /call/cv show status nolog",
	);
}

# parse physical devices
sub parse_pd {
	my $this = shift;

	my (@pd, %pd);
	my $rc = -1;
        my $ctrl;
	my $fh = $this->cmd('pdlist');
	while (<$fh>) {
                if (my($s) = /^Controller = (\d+)\s*$/) {
                        $ctrl = $s;
                        next;
                }
		if (my($s) = /^Status = Success$/) {
			$rc = 0;
		}

		if (my($s) = /^Drive (\/c[0-9]*\/e[0-9]*\/s[0-9]*) \:$/) {
			push(@pd, { %pd }) if %pd;
			%pd = ( dev => $s, state => undef, name => undef, serial => undef, predictive => undef, controller => $ctrl );
			next;
		}

		if (my($s) = /^\d+\:\d+\s+\d+\s+(\w+)\s+[0-9-F]+.*/) {
			$pd{state} = $s;

			if (defined($pd{predictive})) {
				$pd{state} = $pd{predictive};
			}
			next;
		}

		if (my($s) = /^Predictive Failure Count = (\d+)$/) {
			if ($s > 0) {
				$pd{predictive} = 'Predictive';
			}
			next;
		}

		if (my($s) = /^SN = (.+)$/) {
			# trim some spaces
			$s =~ s/\s+/ /g; $s =~ s/^\s+|\s+$//g;
			$pd{serial} = $s;
			next;
		}

		if (my($s) = /^Model (?:Number )?= (.+)$/) {
			# trim some spaces
			$s =~ s/\s+/ /g; $s =~ s/^\s+|\s+$//g;
			$pd{name} = $s;
			next;
		}
	}
	push(@pd, { %pd }) if %pd;

	$this->critical unless close $fh;
	$this->critical if $rc;

	return \@pd;
}

sub parse_ld {
	my $this = shift;

	my (@ld, %ld);
#	my $rc = -1;
        my $ctrl;
	my $fh = $this->cmd('ldinfo');
	while (<$fh>) {
                if (my($s) = /^Controller = (\d+)\s*$/) {
                        $ctrl = $s;
                        next;
                }
#		if (my($s) = /^Status = Success$/) {
#			$rc = 0;
#		}

		if (my($s) = /^(\/c[0-9]*\/v[0-9]*) \:$/) {
			push(@ld, { %ld }) if %ld;
			%ld = ( name => $s, state => undef, controller => $ctrl );
			next;
		}

#		if (my($name) = /Name\s*:\s*(\S+)/) {
#			# Add a symbolic name, if given
#			$ld{name} = $name;
#			next;
#		}

		if (my($type, $state, $cache, $name) = /^\d+\/\d+\s+(\w+\d)\s+(\w+)\s+\S+\s+\S+\s+(\w+).*\wB\s*(?:([\S ]+\S))?\s*$/) {
			$ld{type} = $type;
			$ld{state} = $state;
			$ld{current_cache} = $cache;
			$ld{name} = $name if $name;
			next;
		}

#		if (my($s) = /State\s*:\s*(\S+)/) {
#			$ld{state} = $s;
#			next;
#		}

		if (my($s) = /Write Cache.*=\s*(.+)$/) {
			$ld{default_cache} = $s;
			next;
		}

#		if (my($s) = /^Disk Cache Policy = (.+)$/) {
#			$ld{current_cache} = [split /,\s*/, $s];
#			next;
#		}
	}
	push(@ld, { %ld }) if %ld;

	$this->critical unless close $fh;
#	$this->critical if $rc;

	return \@ld;
}


# check battery
sub parse_bbu {
	my $this = shift;

	return [] unless $this->bbu_monitoring;

	my %default_bbu = (
		name => undef, state => '???', charging_status => '???', missing => undef,
		learn_requested => undef, replacement_required => undef,
		learn_cycle_requested => undef, learn_cycle_active => '???',
		pack_will_fail => undef, temperature => undef, temperature_state => undef,
		voltage => undef, voltage_state => undef
	);

	my (@bbu, %bbu);
        my $ctrl;
	my $fh0 = $this->cmd('batterywarning');
        # Perhaps it's better to use "On Board Memory Size" to determine BBU/CV support
        # If "On Board Memory Size = 0MB" - BBU/CV isn't supported (HBA?)
	while (<$fh0>) {
		if (my($s) = /^Controller = (\d+)\s*$/) {
			#push(@bbu, { %bbu }) if %bbu;
                        $ctrl = $s;
			#$bbu{$ctrl} = %default_bbu;
			#$bbu{$ctrl}{name} = $s;
			next;
		}
                if (my($s) = /^Description = Un-supported Command\s*$/) {
                        $bbu{$ctrl}{unsupported_command} = 'Yes';
                        $bbu{$ctrl}{batterywarning} = 'OFF';
                        next;
                }
                if (my($s) = /^BatteryWarning\s*(\w*)\s*$/) {
                        $bbu{$ctrl}{batterywarning} = $s;
                        next;
                }
	}
        $this->critical unless close $fh0;
        # no controllers? skip early
        #return unless %bbu;

	my $fh = $this->cmd('battery');
	while (<$fh>) {
		if (my($s) = /^Controller = (\d+)\s*$/) {
			#$bbu{name} = $s;
                        $ctrl = $s;
                        $bbu{$ctrl}{name} = $s;
			next;
		}
                if (my($s) = /^\s*\d+\s+Failed\s+\-\s+use \/cx\/cv\s+255\s*$/) {
                        # skip parsing bbu further, proceed parsing cachevault
                        last;
                }
                if (my($s) = /^Description = Un-supported command\s*$/) {
                        $bbu{$ctrl}{unsupported_command} = 'Yes';
                        last;
                }
		if (my($s) = /^Battery State\s*(\w*)\s*$/i) {
			if (!$s) { $s = 'Faulty'; };
			$bbu{$ctrl}{state} = $s;
			next;
		}
		if (my($s) = /^Charging Status\s*(\w*)\s*$/) {
			$bbu{$ctrl}{charging_status} = $s;
			next;
		}
		if (my($s) = /^Battery Pack Missing\s*(\w*)\s*$/) {
			$bbu{$ctrl}{missing} = $s;
			next;
		}
		if (my($s) = /^Replacement required\s*(\w*)\s*$/) {
			$bbu{$ctrl}{replacement_required} = $s;
			next;
		}
		if (my($s) = /^Learn Cycle Requested\s*(\w*)\s*$/) {
			$bbu{$ctrl}{learn_cycle_requested} = $s;
			next;
		}
		if (my($s) = /^Learn Cycle Active\s*(\w*)\s*$/) {
			$bbu{$ctrl}{learn_cycle_active} = $s;
			next;
		}
		if (my($s) = /^Pack is about to fail & should be replaced\s*(\w*)\s*$/) {
			$bbu{$ctrl}{pack_will_fail} = $s;
			next;
		}
		# Temperature: 18 C
		if (my($s) = /^Temperature\s+(\d+) C\s*$/) {
			$bbu{$ctrl}{temperature} = $s;
			next;
		}
		# Temperature : OK
		if (my($s) = /^Temperature\s*(\w*)\s*$/) {
			$bbu{$ctrl}{temperature_state} = $s;
			next;
		}
		# Voltage: 4074 mV
		if (my($s) = /^Voltage\s*(\d+) mV\s*$/) {
			$bbu{$ctrl}{voltage} = $s;
			next;
		}
		# Voltage : OK
		if (my($s) = /^Voltage\s*(\w*)\s*$/) {
			$bbu{$ctrl}{voltage_state} = $s;
			next;
		}

	}
	$this->critical unless close $fh;

	my %cv;
	my $fh2 = $this->cmd('cachevault');
	while (<$fh2>) {
		if (my($s) = /^Controller = (\d+)\s*$/) {
                        $ctrl = $s;
			#push(@bbu, { %bbu }) if %bbu;
			#%bbu = %default_bbu unless $bbu{state};
                        #$bbu{$ctrl} = %default_bbu unless $bbu{$ctrl}{state};
			#$bbu{name} = $s;
			$bbu{$ctrl}{charging_status} = 'None';         # Workaround. TODO: refactor
			$bbu{$ctrl}{pack_will_fail} = 'No';            # Workaround. TODO: refactor
			$bbu{$ctrl}{missing} = 'No';                   # Workaround. TODO: refactor
			$bbu{$ctrl}{learn_cycle_requested} = 'No';     # Workaround. TODO: refactor
			$bbu{$ctrl}{learn_cycle_active} = 'No';        # Workaround. TODO: refactor
			next;
		}
		if (my($s) = /^State\s*(\w*)\s*$/i) {
			#if (!$s) { $s = 'Faulty'; };
			$bbu{$ctrl}{state} = $s;
			next;
		}
                if (my($s) = /^\s*\d+\s+Failed\s+\-\s+(Cachevault is absent)!\s+34\s*$/) {
			$bbu{$ctrl}{missing} = 'Yes';
			$bbu{$ctrl}{state} = $s;
			$bbu{$ctrl}{temperature} = 0; # Workaround. TODO: refactor
			$bbu{$ctrl}{temperature_state} = 'Unknown'; # Workaround. TODO: refactor
			$bbu{$ctrl}{voltage} = 0; # Workaround. TODO: refactor
			$bbu{$ctrl}{voltage_state} = 'Unknown'; # Workaround. TODO: refactor
			$bbu{$ctrl}{replacement_required} = 'Yes';
			next;
		}
                if (my($s) = /^Description = (Un-supported command)\s*$/) {
			$bbu{$ctrl}{missing} = 'Yes';
			$bbu{$ctrl}{state} = $s;
			$bbu{$ctrl}{temperature} = 0; # Workaround. TODO: refactor
			$bbu{$ctrl}{temperature_state} = 'Unknown'; # Workaround. TODO: refactor
			$bbu{$ctrl}{voltage} = 0; # Workaround. TODO: refactor
			$bbu{$ctrl}{voltage_state} = 'Unknown'; # Workaround. TODO: refactor
			$bbu{$ctrl}{replacement_required} = 'No';
                        $bbu{$ctrl}{unsupported_command} = 'Yes';
			next;
		}
		if (my($s) = /^Replacement required\s*(\w*)\s*$/) {
			$bbu{$ctrl}{replacement_required} = $s;
			next;
		}
		# Temperature: 18 C
		if (my($s) = /^Temperature\s+(\d+) C\s*$/) {
			$bbu{$ctrl}{temperature} = $s;
			$bbu{$ctrl}{temperature_state} = 'OK'; # TODO: implement checks of temperature
			next;
		}
		# Voltage: 4074 mV
		if (my($s) = /^Pack Energy\s*(\d+) J\s*$/) {
			$bbu{$ctrl}{voltage} = $s;
			$bbu{$ctrl}{voltage_state} = 'OK'; # TODO: implement checks of energy
			next;
		}
	}
#	$this->critical unless close $fh2; # workaround for unclosed handle

	#push(@bbu, { %bbu }) if %bbu;
        foreach my $key (sort {$a <=> $b} keys %bbu) {
            push(@bbu, $bbu{$key});
        }

	return \@bbu;
}

sub parse {
	my $this = shift;

	my $pd = $this->parse_pd;
	my $ld = $this->parse_ld;
	my $bbu = $this->parse_bbu;

#	my @devs = @$pd if $pd;
#	my @vols = @$ld if $ld;
#	my @bats = @$bbu if $bbu;

	return {
		logical => $ld,
		physical => $pd,
		battery => $bbu,
	};
}

sub check {
	my $this = shift;

	my $c = $this->parse;

	my @vstatus;
	foreach my $vol (@{$c->{logical}}) {
#TODO#		# skip CacheCade for now. #91
#		if ($vol->{type} && $vol->{type} eq 'CacheCade') {
#			next;
#		}

		push(@vstatus, sprintf "%s:%s", $vol->{name}, $vol->{state});
		if ($vol->{state} ne 'Optl') {
			$this->critical;
		}

		# check cache policy
		if ($vol->{current_cache} =~ /WT/) {
			my $default = grep { /WriteThrough/ } $vol->{default_cache};
			# alert if WriteThrough is configured in default
			$this->cache_fail unless $default;
			push(@vstatus, "WriteCache:DISABLED");
		}
	}

	my %dstatus;
	foreach my $dev (sort {$a->{dev} cmp $b->{dev}} @{$c->{physical}}) {
		if ($dev->{state} eq 'Onln' || $dev->{state} eq 'DHS' || $dev->{state} eq 'UGood' || $dev->{state} eq 'GHS') {
			push(@{$dstatus{$dev->{state}}}, sprintf "%s", $dev->{dev});

		} elsif ($dev->{state} eq 'Predictive') {
			$this->warning;
			push(@{$dstatus{$dev->{state}}}, sprintf "%s (%s s/n: %s)", $dev->{dev}, $dev->{name}, $dev->{serial});
		} else {
			$this->critical;
			# TODO: process other statuses
			push(@{$dstatus{$dev->{state}}}, sprintf "%s (%s s/n: %s)", $dev->{dev}, $dev->{name}, $dev->{serial});
		}
	}

	my (%bstatus, @bpdata, @blongout);
	foreach my $bat (sort {$a->{name} cmp $b->{name}} @{$c->{battery}}) {
#		if ($bat->{cstate} && $bat->{cstate} eq 'Failure') {
#			last;
#		}
		if ($bat->{state} !~ /^(Operational|Optimal)$/) {
			# BBU learn cycle in progress.
			if ($bat->{charging_status} =~ /^(Charging|Discharging)$/ && $bat->{learn_cycle_active} eq 'Yes') {
				$this->bbulearn;
			} else {
				$this->critical unless $bat->{batterywarning} eq 'OFF';
			}
		}
		if (defined($bat->{missing}) && $bat->{missing} ne 'No') {
			$this->critical unless $bat->{batterywarning} eq 'OFF';
		}
		if (defined($bat->{replacement_required}) && $bat->{replacement_required} ne 'No') {
			$this->critical unless $bat->{batterywarning} eq 'OFF';
		}
		if (defined($bat->{pack_will_fail}) && $bat->{pack_will_fail} ne 'No') {
			$this->critical unless $bat->{batterywarning} eq 'OFF';
		}
		if (defined($bat->{temperature_state}) && $bat->{temperature_state} ne 'OK') {
			$this->critical unless $bat->{batterywarning} eq 'OFF';
		}
		if (defined($bat->{voltage_state}) && $bat->{voltage_state} ne 'OK') {
			$this->critical unless $bat->{batterywarning} eq 'OFF';
		}

		# Short output.
		#
		# CRITICAL: megacli:[Volumes(1): NoName:Optimal; Devices(2): 06,07=Online; Batteries(1): 0=Non Operational]
		push(@{$bstatus{$bat->{state}}}, sprintf "%d", $bat->{name});
		# Performance data.
		# Return current battery temparature & voltage.
		#
		# Battery0=18;4074
		push(@bpdata, sprintf "Battery%s_T=%s;;;; Battery%s_V=%s;;;;", $bat->{name}, $bat->{temperature}, $bat->{name}, $bat->{voltage});

		# Long output.
		# Detailed plugin output.
		#
		# Battery0:
		#  - State: Non Operational
		#  - Missing: No
		#  - Replacement required: Yes
		#  - About to fail: No
		#  - Temperature: OK (18 °C)
		#  - Voltage: OK (4015 mV)
		push(@blongout, join("\n", grep {/./}
			"Battery$bat->{name}:",
			" - State: $bat->{state}",
                        " - Battery Warning: $bat->{batterywarning}",
			" - Charging status: $bat->{charging_status}",
			" - Learn cycle requested: $bat->{learn_cycle_requested}",
			" - Learn cycle active: $bat->{learn_cycle_active}",
			" - Missing: $bat->{missing}",
			" - Replacement required: $bat->{replacement_required}",
			defined($bat->{pack_will_fail}) ? " - About to fail: $bat->{pack_will_fail}" : "",
			" - Temperature: $bat->{temperature_state} ($bat->{temperature} C)",
			" - Voltage: $bat->{voltage_state} ($bat->{voltage} mV)",
		));
	}

	my @cstatus;
	push(@cstatus, 'Volumes(' . ($#{$c->{logical}} + 1) . '): ' . join(',', @vstatus));
	push(@cstatus, 'Devices(' . ($#{$c->{physical}} + 1) . '): ' . $this->join_status(\%dstatus));
	push(@cstatus, 'Batteries(' . ($#{$c->{battery}} + 1) . '): ' . $this->join_status(\%bstatus)) if @{$c->{battery}};
	my @status = join('; ', @cstatus);

	my @pdata;
	push(@pdata,
		join('\n', @bpdata)
	);
	my @longout;
	push(@longout,
		join('\n', @blongout)
	);
	return unless @status;

	# denote this plugin as ran ok
	$this->ok;

	$this->message(join(' ', @status));
	$this->perfdata(join(' ', @pdata));
	$this->longoutput(join(' ', @longout));
}

1;
