/*
 * All instance types (flavors) with aggregated pricing across regions.
 * Single-AZ (metro=0) prices are used for the headline numbers, the
 * multi-AZ (metro=1) minimum is provided separately.
 */
SELECT
	t."instanceType",
	t."instanceFamily",
	t."instanceFamilyName",
	t."category",
	t."vCpu",
	t."ramGb",
	t."hardware",
	t."cpuOverprovisioning",
	t."localDisk",
	t."localDiskGb",
	t."gpu",
	t."gpuCount",
	t."cpuArchitecture",
	t."cpuVendor",
	t."cpuModel",
	t."cpuBaseClockGhz",
	t."gpuVendor",
	t."gpuModel",
	t."gpuMemoryGb",
	/* number of regions the flavor is offered in (single-AZ) */
	(SELECT COUNT(DISTINCT p2."region")
		FROM "instance-prices" p2
		WHERE p2."instanceType" = t."instanceType") AS "regionCount",
	/* Single-AZ pricing (metro = 0) */
	MIN(CASE WHEN p."metro" = 0 THEN p."priceHour"  END) AS "minHour",
	AVG(CASE WHEN p."metro" = 0 THEN p."priceHour"  END) AS "avgHour",
	MIN(CASE WHEN p."metro" = 0 THEN p."priceMonth" END) AS "minMonth",
	AVG(CASE WHEN p."metro" = 0 THEN p."priceMonth" END) AS "avgMonth",
	/* Multi-AZ pricing (metro = 1) */
	MIN(CASE WHEN p."metro" = 1 THEN p."priceHour"  END) AS "minHourMetro",
	MIN(CASE WHEN p."metro" = 1 THEN p."priceMonth" END) AS "minMonthMetro"
FROM "instance-types" t
LEFT JOIN "instance-prices" p ON p."instanceType" = t."instanceType"
GROUP BY t."instanceType"
ORDER BY t."vCpu" ASC, t."ramGb" ASC, t."instanceType" ASC;
