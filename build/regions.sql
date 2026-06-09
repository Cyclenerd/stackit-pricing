/*
 * STACKIT regions / locations
 *
 * STACKIT currently operates two regions in Germany.
 * Region codes ending with "-m" (metro) provide Multi-AZ deployments.
 * The metro flag is handled per price row, so only the base regions live here.
 */

DELETE FROM "regions";

INSERT INTO "regions"
	("region", "regionName", "city", "country", "continent")
VALUES
	('eu01', 'Germany South', 'Neckarsulm', 'Germany', 'Europe'),
	('eu02', 'Austria West', 'Ostermiething', 'Austria', 'Europe');
