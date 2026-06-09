#!/usr/bin/perl

# Copyright 2026 Nils Knieling. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Import STACKIT Compute Engine pricing (pricing.json from PIM /v1/skus)
# into the SQLite database.
#
# Usage:
#   perl import.pl < pricing.json
#

use strict;
use warnings;
use DBI;
use JSON::XS;

my $dbFile = './stackit.db';
my $db = DBI->connect("dbi:SQLite:dbname=$dbFile", "", "", {
	RaiseError => 1,
	AutoCommit => 0,
}) or die "ERROR: Cannot connect $DBI::errstr\n";

# Read whole JSON from STDIN
my $jsonText = do { local $/; <STDIN> };
die "ERROR: No JSON input!\n" unless $jsonText;
my $data = decode_json($jsonText);
my $services = $data->{'services'} or die "ERROR: No 'services' in JSON!\n";

print "Import STACKIT pricing:\n";
print "\tlastUpdatedAt: " . ($data->{'lastUpdatedAt'} // '?') . "\n";
print "\tservices:      " . scalar(@$services) . "\n";

# Prepared statements
my $insertType = $db->prepare(q{
	INSERT OR REPLACE INTO "instance-types"
		("instanceType", "instanceFamily", "instanceFamilyName", "category",
		 "vCpu", "ramGb", "hardware", "cpuOverprovisioning",
		 "gpu", "gpuCount")
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
});

my $insertPrice = $db->prepare(q{
	INSERT OR REPLACE INTO "instance-prices"
		("instanceType", "region", "metro", "sku", "id", "maturity",
		 "deprecated", "priceHour", "priceMonth", "currency")
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
});

my $insertBlockStorage = $db->prepare(q{
	INSERT OR REPLACE INTO "block-storage"
		("class", "region", "metro", "name", "storageType", "storageKind",
		 "billingUnit", "maxIops", "maxThroughputMb", "sku", "id", "maturity",
		 "deprecated", "priceHour", "priceMonth", "currency")
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
});

# Collect type info (de-duplicated) so we only insert each flavor once.
my %types;     # flavor => hashref
my $priceCount = 0;
my $blockStorageCount = 0;

foreach my $svc (@$services) {
	# We only care about Virtual Machines (Compute Engine + GPU)
	next unless ($svc->{'generalProductGroup'} // '') eq 'Virtual Machines';

	my $attr   = $svc->{'attributes'} || {};
	my $flavor = $attr->{'flavor'};
	next unless defined $flavor && length $flavor;

	my $region = lc($svc->{'region'} // '');
	next unless $region;

	my $metro = $attr->{'metro'} ? 1 : 0;

	# --- Family + family name ---
	my ($family) = $flavor =~ /^([a-z]+\d+[a-z]*)/;  # e.g. c1, m2i, b1a, n1
	$family //= $flavor;
	my $familyName = $svc->{'title'} // '';
	$familyName =~ s/-[a-z0-9].*$//;                 # strip "-c1.1-EU01-m"
	$familyName =~ s/\s+$//;

	# --- vCPU / RAM / hardware ---
	my $vCpu     = $attr->{'vCPU'} // 0;
	my $ramGb    = $attr->{'ram'}  // 0;
	my $hardware = $attr->{'hardware'} // '';
	my $overprov = $attr->{'cpuOverprovisioning'} ? 1 : 0;

	# --- Local disk ---
	# NOTE: The STACKIT price API does NOT expose local disk information and it
	# cannot be reliably derived from the flavor name (the trailing 'd' is not a
	# guaranteed indicator). Local disk size is maintained manually in
	# instance-types-extra.sql via the localDisk / localDiskGb columns.

	# --- GPU ---
	my $isGpu    = ($hardware eq 'GPU' || ($svc->{'product'} // '') eq 'GPU Server') ? 1 : 0;
	my $gpuCount = 0;
	if ($flavor =~ /\.g(\d+)$/) { $gpuCount = $1; }  # e.g. n1.14d.g1 -> 1, n3.104d.g8 -> 8

	# Store / merge type (price independent facts).
	# Keep the richest record (prefer non-metro, ga rows).
	$types{$flavor} = {
		instanceType        => $flavor,
		instanceFamily      => $family,
		instanceFamilyName  => $familyName,
		category            => $svc->{'category'} // '',
		vCpu                => $vCpu,
		ramGb               => $ramGb,
		hardware            => $hardware,
		cpuOverprovisioning => $overprov,
		gpu                 => $isGpu,
		gpuCount            => $gpuCount,
	} unless exists $types{$flavor};

	# --- Price row ---
	my $priceHour  = $svc->{'price'}        // 0;
	my $priceMonth = $svc->{'monthlyPrice'} // 0;
	# Normalize currency symbol to ISO code
	my $currency   = ($svc->{'currency'} // '') eq '$' ? 'USD' : 'EUR';

	$insertPrice->execute(
		$flavor,
		$region,
		$metro,
		$svc->{'sku'} // '',
		$svc->{'id'}  // '',
		$svc->{'maturityModelState'} // '',
		(($svc->{'deprecated'} // 'No') =~ /^y/i) ? 1 : 0,
		$priceHour + 0,
		$priceMonth + 0,
		$currency,
	);
	$priceCount++;
}

# --- Block Storage ---
foreach my $svc (@$services) {
	next unless ($svc->{'generalProductGroup'} // '') eq 'Block Storage';

	my $attr   = $svc->{'attributes'} || {};
	my $region = lc($svc->{'region'} // '');
	next unless $region;

	my $metro = $attr->{'metro'} ? 1 : 0;

	# Stable class key:
	#  - performance volumes carry a "class" (e.g. storage_premium_perf0)
	#  - capacity / backup volumes have class=null, so derive a slug from the title
	my $class = $attr->{'class'};
	if (!defined $class || !length $class) {
		$class = $svc->{'title'} // '';
		$class =~ s/-EU0\d(-m)?$//i;        # strip region/metro suffix
		$class =~ s/^Block Storage (for )?//i;
		$class =~ s/\s+Premium//i;
		$class =~ s/^\s+|\s+$//g;
		$class = lc($class);
		$class =~ s/[^a-z0-9]+/-/g;          # slugify
		$class =~ s/^-+|-+$//g;
		$class = 'capacity' unless length $class;
	}

	# Human readable name: cleaned title without region/metro suffix
	my $name = $svc->{'title'} // '';
	$name =~ s/-EU0\d(-m)?$//i;
	$name =~ s/^Block Storage (for )?//i;
	$name =~ s/^\s+|\s+$//g;

	my $priceHour  = $svc->{'price'}        // 0;
	my $priceMonth = $svc->{'monthlyPrice'} // 0;
	my $currency   = ($svc->{'currency'} // '') eq '$' ? 'USD' : 'EUR';

	$insertBlockStorage->execute(
		$class,
		$region,
		$metro,
		$name,
		$attr->{'type'}    // '',
		$attr->{'storage'} // '',
		$svc->{'unitBilling'} // '',
		($attr->{'maxIOPerSec'}   // 0) + 0,
		($attr->{'maxTroughInMB'} // 0) + 0,
		$svc->{'sku'} // '',
		$svc->{'id'}  // '',
		$svc->{'maturityModelState'} // '',
		(($svc->{'deprecated'} // 'No') =~ /^y/i) ? 1 : 0,
		$priceHour + 0,
		$priceMonth + 0,
		$currency,
	);
	$blockStorageCount++;
}

# Insert all unique types
foreach my $flavor (sort keys %types) {
	my $t = $types{$flavor};
	$insertType->execute(
		$t->{instanceType},
		$t->{instanceFamily},
		$t->{instanceFamilyName},
		$t->{category},
		$t->{vCpu},
		$t->{ramGb},
		$t->{hardware},
		$t->{cpuOverprovisioning},
		$t->{gpu},
		$t->{gpuCount},
	);
}

$db->commit;

print "\tinstance-types:  " . scalar(keys %types) . "\n";
print "\tinstance-prices: $priceCount\n";
print "\tblock-storage:   $blockStorageCount\n";

$insertType->finish;
$insertPrice->finish;
$insertBlockStorage->finish;
$db->disconnect;

print "DONE\n";
