/*
 * Block Storage classes with prices pivoted per region + availability.
 * One row per storage class.
 *
 * Capacity / backup volumes are priced "per GB/hour"; performance classes
 * are priced "per disk/hour" (fixed size per class).
 */
SELECT
	b."class",
	MAX(b."name")            AS "name",
	MAX(b."storageType")     AS "storageType",
	MAX(b."storageKind")     AS "storageKind",
	MAX(b."billingUnit")     AS "billingUnit",
	MAX(b."maxIops")         AS "maxIops",
	MAX(b."maxThroughputMb") AS "maxThroughputMb",
	/* eu01 */
	MAX(CASE WHEN b."region" = 'eu01' AND b."metro" = 0 THEN b."priceHour"  END) AS "eu01Hour",
	MAX(CASE WHEN b."region" = 'eu01' AND b."metro" = 1 THEN b."priceHour"  END) AS "eu01HourMetro",
	MAX(CASE WHEN b."region" = 'eu01' AND b."metro" = 0 THEN b."priceMonth" END) AS "eu01Month",
	MAX(CASE WHEN b."region" = 'eu01' AND b."metro" = 1 THEN b."priceMonth" END) AS "eu01MonthMetro",
	/* eu02 */
	MAX(CASE WHEN b."region" = 'eu02' AND b."metro" = 0 THEN b."priceHour"  END) AS "eu02Hour",
	MAX(CASE WHEN b."region" = 'eu02' AND b."metro" = 1 THEN b."priceHour"  END) AS "eu02HourMetro",
	MAX(CASE WHEN b."region" = 'eu02' AND b."metro" = 0 THEN b."priceMonth" END) AS "eu02Month",
	MAX(CASE WHEN b."region" = 'eu02' AND b."metro" = 1 THEN b."priceMonth" END) AS "eu02MonthMetro"
FROM "block-storage" b
GROUP BY b."class"
ORDER BY
	/* capacity/backup first, then performance classes by IOPS */
	CASE WHEN MAX(b."storageType") = 'performance' THEN 1 ELSE 0 END ASC,
	MAX(b."maxIops") ASC,
	b."class" ASC;
