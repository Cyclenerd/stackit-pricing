/*
 * Single instance type (flavor) details.
 * Placeholder __INSTANCE_TYPE__ is replaced by web.pl.
 */
SELECT
	t.*,
	(SELECT COUNT(DISTINCT p."region")
		FROM "instance-prices" p
		WHERE p."instanceType" = t."instanceType") AS "regionCount",
	(SELECT MIN(p."priceHour")
		FROM "instance-prices" p
		WHERE p."instanceType" = t."instanceType" AND p."metro" = 0) AS "minHour",
	(SELECT MIN(p."priceMonth")
		FROM "instance-prices" p
		WHERE p."instanceType" = t."instanceType" AND p."metro" = 0) AS "minMonth"
FROM "instance-types" t
WHERE t."instanceType" = '__INSTANCE_TYPE__';
