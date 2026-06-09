/*
 * All regions with the number of available instance types.
 */
SELECT
	r."region",
	r."regionName",
	r."city",
	r."country",
	r."continent",
	(SELECT COUNT(DISTINCT p."instanceType")
		FROM "instance-prices" p
		WHERE p."region" = r."region") AS "instanceCount",
	(SELECT COUNT(DISTINCT p."instanceType")
		FROM "instance-prices" p
		WHERE p."region" = r."region" AND p."metro" = 1) AS "instanceCountMetro"
FROM "regions" r
ORDER BY r."region" ASC;
