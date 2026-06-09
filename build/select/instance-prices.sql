/*
 * All prices (per region, single + multi AZ) for one instance type.
 * Placeholder __INSTANCE_TYPE__ is replaced by web.pl.
 */
SELECT
	p."instanceType",
	p."region",
	p."metro",
	p."sku",
	p."maturity",
	p."deprecated",
	p."priceHour",
	p."priceMonth",
	p."currency",
	r."regionName",
	r."city",
	r."country",
	r."continent"
FROM "instance-prices" p
LEFT JOIN "regions" r ON r."region" = p."region"
WHERE p."instanceType" = '__INSTANCE_TYPE__'
ORDER BY p."region" ASC, p."metro" ASC;
