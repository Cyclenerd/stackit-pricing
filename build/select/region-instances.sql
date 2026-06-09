/*
 * All instance types available in one region, with single + multi AZ prices.
 * Placeholder __REGION__ is replaced by web.pl.
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
	MAX(CASE WHEN p."metro" = 0 THEN p."priceHour"  END) AS "priceHour",
	MAX(CASE WHEN p."metro" = 0 THEN p."priceMonth" END) AS "priceMonth",
	MAX(CASE WHEN p."metro" = 1 THEN p."priceHour"  END) AS "priceHourMetro",
	MAX(CASE WHEN p."metro" = 1 THEN p."priceMonth" END) AS "priceMonthMetro"
FROM "instance-prices" p
JOIN "instance-types" t ON t."instanceType" = p."instanceType"
WHERE p."region" = '__REGION__'
GROUP BY t."instanceType"
ORDER BY t."vCpu" ASC, t."ramGb" ASC, t."instanceType" ASC;
