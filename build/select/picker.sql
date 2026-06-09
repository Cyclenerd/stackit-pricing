/*
 * Flat, denormalized rows for the interactive Instance Picker (AG Grid)
 * and the CSV export. One row per instance type + region + availability.
 */
SELECT
	t."instanceType",
	t."instanceFamily",
	t."instanceFamilyName",
	t."category",
	t."vCpu",
	t."ramGb",
	t."hardware",
	t."cpuArchitecture",
	t."cpuVendor",
	t."cpuModel",
	t."cpuBaseClockGhz",
	t."cpuOverprovisioning",
	t."localDisk",
	t."localDiskGb",
	t."gpu",
	t."gpuCount",
	t."gpuVendor",
	t."gpuModel",
	t."gpuMemoryGb",
	p."region",
	r."regionName",
	r."city",
	r."country",
	p."metro",
	p."sku",
	p."maturity",
	p."deprecated",
	p."priceHour",
	p."priceMonth",
	p."currency"
FROM "instance-prices" p
JOIN "instance-types" t ON t."instanceType" = p."instanceType"
LEFT JOIN "regions" r ON r."region" = p."region"
ORDER BY t."vCpu" ASC, t."instanceType" ASC, p."region" ASC, p."metro" ASC;
