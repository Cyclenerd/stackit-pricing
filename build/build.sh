#!/usr/bin/env bash

#
# Build the STACKIT Compute Engine pricing website.
#

set -e

MY_DATABASE="stackit.db"

# Download the latest STACKIT price list (skip with SKIP_DOWNLOAD=1)
if [ -z "$SKIP_DOWNLOAD" ]; then
	echo "Download STACKIT price list..."
	curl --fail -s "https://pim.api.stackit.cloud/v1/skus" -o pricing.json
fi

# Create database
echo "Create database..."
rm -f "$MY_DATABASE"
sqlite3 "$MY_DATABASE" < create.sql

# Seed regions
echo "Seed regions..."
sqlite3 "$MY_DATABASE" < regions.sql

# Import pricing
echo "Import pricing..."
perl import.pl < pricing.json

# Apply hand maintained extra instance type information
echo "Apply extra instance type information..."
sqlite3 "$MY_DATABASE" < instance-types-extra.sql

# Export CSV + SQL
echo "Export..."
bash export.sh

# Generate website
echo "Generate website..."
perl web.pl

echo "DONE"
