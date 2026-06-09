#!/usr/bin/env bash

#
# Export the STACKIT database as CSV and gzip compressed SQL dump.
#

MY_DATABASE="stackit.db"
CSV_EXPORT="stackit-instances.csv"
SQL_EXPORT="stackit.sql"

echo "Export"

echo -e "\tSQL"
echo > "$SQL_EXPORT" || exit 9
MY_TABLES=(
	"regions"
	"instance-types"
	"instance-prices"
	"block-storage"
)
for MY_TABLE in "${MY_TABLES[@]}"; do
	{
		echo "DROP TABLE IF EXISTS \"$MY_TABLE\";"
		sqlite3 "$MY_DATABASE" ".dump $MY_TABLE"
	} >> "$SQL_EXPORT" || exit 9
done
gzip -fk "$SQL_EXPORT" || exit 9

echo -e "\tCSV"
sqlite3 -header -csv "$MY_DATABASE" < "./select/picker.sql" > "$CSV_EXPORT" || exit 9

echo "DONE"
