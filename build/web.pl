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
# Generate the static STACKIT Compute Engine pricing website.
#

use strict;
use warnings;
use DBI;
use Encode qw(decode);
use JSON::XS;
use Template;
use File::Copy;

# Open DB
my $dbFile = './stackit.db';
my $db = DBI->connect("dbi:SQLite:dbname=$dbFile", "", "") or die "ERROR: Cannot connect $DBI::errstr\n";

# Read a SQL file into a string
sub read_sql {
	my ($file) = @_;
	open my $fh, "<", $file or die "ERROR: Cannot open SQL file '$file': $!\n";
	local $/;
	my $sql = <$fh>;
	close $fh;
	return $sql;
}

# Run a SELECT and return arrayref of hashrefs
sub fetch_all {
	my ($sql) = @_;
	my $sth = $db->prepare($sql);
	$sth->execute();
	my @rows;
	while (my $row = $sth->fetchrow_hashref) { push @rows, $row }
	$sth->finish;
	return \@rows;
}

# Price data timestamp (lastUpdatedAt) from the source JSON, if present
my $priceUpdatedAt = '';
if (open my $pjFh, "<", "pricing.json") {
	local $/;
	my $pj = eval { decode_json(<$pjFh>) };
	close $pjFh;
	$priceUpdatedAt = $pj->{'lastUpdatedAt'} if ($pj && $pj->{'lastUpdatedAt'});
}

print "Select:\n";

# All instance types (aggregated)
print "\tInstance Types\n";
my $instances = fetch_all(read_sql("./select/instances.sql"));

# Regions
print "\tRegions\n";
my $regions = fetch_all(read_sql("./select/regions.sql"));

# Picker / export rows (flat)
print "\tPicker rows\n";
my $pickerRows = fetch_all(read_sql("./select/picker.sql"));

# Block Storage
print "\tBlock Storage\n";
my $blockStorage = fetch_all(read_sql("./select/block-storage.sql"));

# --- Build filtered lists for the family / hardware pages ---
my %byFamily = (
	compute => [ grep { $_->{instanceFamilyName} eq 'Compute Optimized Server' } @$instances ],
	general => [ grep { $_->{instanceFamilyName} eq 'General Purpose Server' }   @$instances ],
	memory  => [ grep { $_->{instanceFamilyName} eq 'Memory Optimized Server' }  @$instances ],
	tiny    => [ grep { $_->{instanceFamilyName} eq 'Tiny Server' }              @$instances ],
	gpu     => [ grep { $_->{gpu} }                                              @$instances ],
);
my %byHardware = (
	intel => [ grep { $_->{hardware} eq 'Intel' } @$instances ],
	amd   => [ grep { $_->{hardware} eq 'AMD' }   @$instances ],
	arm   => [ grep { $_->{hardware} eq 'ARM' }   @$instances ],
);

my %counts = (
	all     => scalar(@$instances),
	compute => scalar(@{$byFamily{compute}}),
	general => scalar(@{$byFamily{general}}),
	memory  => scalar(@{$byFamily{memory}}),
	tiny    => scalar(@{$byFamily{tiny}}),
	gpu     => scalar(@{$byFamily{gpu}}),
	intel   => scalar(@{$byHardware{intel}}),
	amd     => scalar(@{$byHardware{amd}}),
	arm     => scalar(@{$byHardware{arm}}),
);

# Export file sizes (in MB), if the exports already exist
sub file_size_mb {
	my ($file) = @_;
	my $bytes = -s $file;
	return '0.00' unless $bytes;
	return sprintf('%.2f', $bytes / 1048576);
}
my $csvFileSize = file_size_mb('stackit-instances.csv');
my $sqlFileSize = file_size_mb('stackit.sql.gz');

# Template engine
mkdir('../web/');
my $gmtime    = gmtime();
my $timestamp = time();
my $template  = Template->new(
	INCLUDE_PATH => './src',
	PRE_PROCESS  => 'config.tt2',
	VARIABLES => {
		'gmtime'           => $gmtime,
		'timestamp'        => $timestamp,
		'priceUpdatedAt'   => $priceUpdatedAt,
		'counts'           => \%counts,
		'csvFileSize'      => $csvFileSize,
		'sqlFileSize'      => $sqlFileSize,
		'gitHubServerUrl'  => $ENV{'GITHUB_SERVER_URL'} || '',
		'gitHubRepository' => $ENV{'GITHUB_REPOSITORY'} || '',
		'gitHubRunId'      => $ENV{'GITHUB_RUN_ID'}     || '',
	}
);

# --- Instance type list pages (all + filtered) ---
print "Instance Type list pages:\n";
my @listPages = (
	{
		file => 'instances.html', filter => 'all', list => $instances,
		heading => 'STACKIT Compute Engine Instance Types',
		title   => 'STACKIT Compute Engine Instance Types',
		desc    => 'List of all STACKIT Compute Engine instance types across both regions with vCPU, memory, hardware and pricing.',
		intro   => "STACKIT offers <mark>$counts{all}</mark> Compute Engine instance types in total.",
	},
	{
		file => 'compute-optimized.html', filter => 'compute', list => $byFamily{compute},
		heading => 'Compute Optimized Instance Types',
		title   => 'STACKIT Compute Optimized Instance Types',
		desc    => 'STACKIT Compute Optimized Server instance types with high vCPU-to-memory ratio and pricing.',
		intro   => "STACKIT offers <mark>$counts{compute}</mark> Compute Optimized Server instance types.",
	},
	{
		file => 'general-purpose.html', filter => 'general', list => $byFamily{general},
		heading => 'General Purpose Instance Types',
		title   => 'STACKIT General Purpose Instance Types',
		desc    => 'STACKIT General Purpose Server instance types with a balanced vCPU-to-memory ratio and pricing.',
		intro   => "STACKIT offers <mark>$counts{general}</mark> General Purpose Server instance types.",
	},
	{
		file => 'memory-optimized.html', filter => 'memory', list => $byFamily{memory},
		heading => 'Memory Optimized Instance Types',
		title   => 'STACKIT Memory Optimized Instance Types',
		desc    => 'STACKIT Memory Optimized Server instance types with a high memory-to-vCPU ratio and pricing.',
		intro   => "STACKIT offers <mark>$counts{memory}</mark> Memory Optimized Server instance types.",
	},
	{
		file => 'tiny.html', filter => 'tiny', list => $byFamily{tiny},
		heading => 'Tiny Instance Types',
		title   => 'STACKIT Tiny Instance Types',
		desc    => 'STACKIT Tiny Server instance types for small / shared workloads and pricing.',
		intro   => "STACKIT offers <mark>$counts{tiny}</mark> Tiny Server instance types.",
	},
	{
		file => 'gpu.html', filter => 'gpu', list => $byFamily{gpu},
		heading => 'GPU Instance Types',
		title   => 'STACKIT GPU Instance Types',
		desc    => 'STACKIT GPU Server instance types for AI / ML / HPC workloads and pricing.',
		intro   => "STACKIT offers <mark>$counts{gpu}</mark> GPU Server instance types.",
	},
	{
		file => 'intel.html', filter => 'intel', list => $byHardware{intel},
		heading => 'Intel Instance Types',
		title   => 'STACKIT Intel Instance Types',
		desc    => 'STACKIT Compute Engine instance types running on Intel hardware and pricing.',
		intro   => "STACKIT offers <mark>$counts{intel}</mark> instance types on Intel hardware.",
	},
	{
		file => 'amd.html', filter => 'amd', list => $byHardware{amd},
		heading => 'AMD Instance Types',
		title   => 'STACKIT AMD Instance Types',
		desc    => 'STACKIT Compute Engine instance types running on AMD hardware and pricing.',
		intro   => "STACKIT offers <mark>$counts{amd}</mark> instance types on AMD hardware.",
	},
	{
		file => 'arm.html', filter => 'arm', list => $byHardware{arm},
		heading => 'ARM Instance Types',
		title   => 'STACKIT ARM Instance Types',
		desc    => 'STACKIT Compute Engine instance types running on ARM hardware and pricing.',
		intro   => "STACKIT offers <mark>$counts{arm}</mark> instance types on ARM hardware.",
	},
);

foreach my $page (@listPages) {
	print "\t$page->{file}\n";
	$template->process(
		'instances.tt2',
		{
			'instances'       => $page->{list},
			'activeFilter'    => $page->{filter},
			'pageFile'        => $page->{file},
			'pageHeading'     => $page->{heading},
			'pageTitle'       => $page->{title},
			'pageDescription' => $page->{desc},
			'pageIntro'       => $page->{intro},
			'regions'         => $regions,
		},
		"../web/$page->{file}"
	) || die "Template process failed: ", $template->error(), "\n";
}

# --- Block Storage ---
print "Block Storage:\n\tblock-storage.html\n";
$template->process(
	'block-storage.tt2',
	{ 'blockStorage' => $blockStorage },
	'../web/block-storage.html'
) || die "Template process failed: ", $template->error(), "\n";

# --- Regions list ---
print "Regions:\n\tregions.html\n";
$template->process(
	'regions.tt2',
	{ 'regions' => $regions },
	'../web/regions.html'
) || die "Template process failed: ", $template->error(), "\n";

# --- Region detail pages ---
print "Region details:\n";
my $regionInstancesSql = read_sql("./select/region-instances.sql");
foreach my $region (@$regions) {
	my $code = $region->{region};
	print "\t$code\n";
	my $sql = $regionInstancesSql;
	$sql =~ s/__REGION__/$code/g;
	my $regionInstances = fetch_all($sql);
	$template->process(
		'region.tt2',
		{
			'region'          => $region,
			'regionInstances' => $regionInstances,
			'regions'         => $regions,
		},
		"../web/$code.html"
	) || die "Template process failed: ", $template->error(), "\n";
}

# --- Instance type detail pages ---
print "Instance type details:\n";
my $instanceSql       = read_sql("./select/instance.sql");
my $instancePricesSql = read_sql("./select/instance-prices.sql");
foreach my $inst (@$instances) {
	my $type = $inst->{instanceType};
	print "\t$type\n";

	my $iSql = $instanceSql;
	$iSql =~ s/__INSTANCE_TYPE__/$type/g;
	my $instanceRows = fetch_all($iSql);
	my $instance = $instanceRows->[0] || $inst;

	my $pSql = $instancePricesSql;
	$pSql =~ s/__INSTANCE_TYPE__/$type/g;
	my $instancePrices = fetch_all($pSql);

	$template->process(
		'instance.tt2',
		{
			'instance'       => $instance,
			'instancePrices' => $instancePrices,
			'regions'        => $regions,
		},
		"../web/$type.html"
	) || die "Template process failed: ", $template->error(), "\n";
}

# --- Picker ---
print "Instance Picker:\n";
print "\tpicker.js\n";
$template->process('picker.js', {}, '../web/picker.js') || die "Template process failed: ", $template->error(), "\n";
print "\tinstances.json\n";
my $json = encode_json($pickerRows);
$json = decode('UTF-8', $json); # force UTF-8
$template->process('instances-json.tt2', { 'json' => $json }, '../web/instances.json')
	|| die "Template process failed: ", $template->error(), "\n";

# --- Misc pages ---
print "Misc:\n";
my @miscPages = ('404', 'download', 'index', 'picker', 'robots', 'sitemap');
foreach my $misc (@miscPages) {
	print "\t$misc\n";
	my $ext = ($misc eq 'robots' || $misc eq 'sitemap') ? 'txt' : 'html';
	$template->process(
		"$misc.tt2",
		{
			'regions'   => $regions,
			'instances' => $instances,
		},
		"../web/$misc.$ext"
	) || die "Template process failed: ", $template->error(), "\n";
}

# --- Static assets ---
mkdir('../web/img/');
foreach my $image (glob("./src/img/*.png")) {
	my ($name) = $image =~ m{([^/]+)$};
	copy($image, "../web/img/$name") || warn "WARN: Cannot copy '$image'\n";
}
foreach my $favicon (glob("./src/img/favicon/*")) {
	my ($name) = $favicon =~ m{([^/]+)$};
	next if -d $favicon;
	copy($favicon, "../web/$name") || warn "WARN: Cannot copy '$favicon'\n";
}

# --- Exports (created by export.sh) ---
foreach my $export ('stackit-instances.csv', 'stackit.sql.gz') {
	copy("./$export", "../web/$export") || warn "WARN: Cannot copy '$export' (run export.sh first)\n";
}

$db->disconnect;
