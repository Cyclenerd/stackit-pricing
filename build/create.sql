/*
 * Create SQLite3 database for STACKIT Compute Engine pricing information
 *
 * Data source: STACKIT Price Information Model (PIM) API
 *   curl "https://pim.api.stackit.cloud/v1/skus" -o pricing.json
 *
 * The schema is intentionally split so that additional, hand maintained
 * information (e.g. exact CPU architecture / model, base clock, GPU model, ...)
 * can be added later via simple SQL files without touching the imported data.
 */

/* ------------------------------------------------------------------ */
/* Regions / Locations                                                */
/* ------------------------------------------------------------------ */
DROP TABLE IF EXISTS "regions";
CREATE TABLE "regions" (
	"region"        TEXT NOT NULL DEFAULT "",  /* Region code, i.e.: eu01, eu02 */
	"regionName"    TEXT NOT NULL DEFAULT "",  /* Human readable name */
	"city"          TEXT NOT NULL DEFAULT "",  /* City / data center location */
	"country"       TEXT NOT NULL DEFAULT "",  /* Country */
	"continent"     TEXT NOT NULL DEFAULT "",  /* Continent */
	PRIMARY KEY("region")
);

/* ------------------------------------------------------------------ */
/* Instance types (flavors)                                           */
/* ------------------------------------------------------------------ */
/* One row per unique flavor (e.g. c1.1, m2i.4d, n1.14d.g1).          */
/* This table holds the static, region independent facts.             */
DROP TABLE IF EXISTS "instance-types";
CREATE TABLE "instance-types" (
	"instanceType"        TEXT NOT NULL DEFAULT "",   /* Flavor, i.e.: c1.1, m2i.4, n1.14d.g1 */
	"instanceFamily"      TEXT NOT NULL DEFAULT "",   /* Family prefix, i.e.: c1, m2i, n1 */
	"instanceFamilyName"  TEXT NOT NULL DEFAULT "",   /* Product name, i.e.: Compute Optimized Server */
	"category"            TEXT NOT NULL DEFAULT "",   /* STACKIT category, i.e.: Compute Engine, Compute Engine GPU */
	"vCpu"                INTEGER NOT NULL DEFAULT "0", /* vCPUs */
	"ramGb"               REAL NOT NULL DEFAULT "0.0", /* Memory in GB */
	"hardware"            TEXT NOT NULL DEFAULT "",   /* Reported hardware: Intel, AMD, ARM, GPU */
	"cpuOverprovisioning" INTEGER NOT NULL DEFAULT "0", /* 1 = vCPUs are over-provisioned (shared) */
	"gpu"                 INTEGER NOT NULL DEFAULT "0", /* 1 = GPU server */
	"gpuCount"            INTEGER NOT NULL DEFAULT "0", /* Number of GPUs (parsed from name, i.e. g4 -> 4) */
	/* ---- Optional fields, filled later via extra SQL (see *.sql) ---- */
	/* NOTE: The STACKIT price API does NOT expose local disk info and it    */
	/* cannot be reliably derived from the flavor name. Maintain it manually. */
	"localDisk"           INTEGER NOT NULL DEFAULT "0", /* 1 = flavor has local disk (curated) */
	"localDiskGb"         REAL NOT NULL DEFAULT "0.0", /* Local disk size in GB (curated) */
	"cpuArchitecture"     TEXT NOT NULL DEFAULT "",   /* i.e.: x86_64, arm64 */
	"cpuVendor"           TEXT NOT NULL DEFAULT "",   /* i.e.: Intel, AMD, Ampere */
	"cpuModel"            TEXT NOT NULL DEFAULT "",   /* i.e.: Intel Xeon ... */
	"cpuBaseClockGhz"     REAL NOT NULL DEFAULT "0.0", /* CPU base clock (GHz) */
	"gpuVendor"           TEXT NOT NULL DEFAULT "",   /* i.e.: NVIDIA */
	"gpuModel"            TEXT NOT NULL DEFAULT "",   /* i.e.: NVIDIA H100 */
	"gpuMemoryGb"         REAL NOT NULL DEFAULT "0.0", /* Total GPU memory (GB) */
	"notes"               TEXT NOT NULL DEFAULT "",   /* Free text notes */
	PRIMARY KEY("instanceType")
);

/* ------------------------------------------------------------------ */
/* Instance prices                                                    */
/* ------------------------------------------------------------------ */
/* One row per flavor + region + availability (single / multi AZ).    */
/* STACKIT has no spot / reserved tiers, only on-demand pay-per-use.  */
DROP TABLE IF EXISTS "instance-prices";
CREATE TABLE "instance-prices" (
	"instanceType"  TEXT NOT NULL DEFAULT "",   /* -> instance-types.instanceType */
	"region"        TEXT NOT NULL DEFAULT "",   /* -> regions.region */
	"metro"         INTEGER NOT NULL DEFAULT "0", /* 1 = Multi-AZ (region code with '-m'), 0 = Single-AZ */
	"sku"           TEXT NOT NULL DEFAULT "",   /* STACKIT SKU, i.e.: ST-0008701 */
	"id"            TEXT NOT NULL DEFAULT "",   /* STACKIT internal id, i.e.: STA_SKU_14552896 */
	"maturity"      TEXT NOT NULL DEFAULT "",   /* maturityModelState, i.e.: ga, beta */
	"deprecated"    INTEGER NOT NULL DEFAULT "0", /* 1 = deprecated */
	"priceHour"     REAL DEFAULT "0.0",         /* Price per hour (EUR) */
	"priceMonth"    REAL DEFAULT "0.0",         /* Price per month (EUR) */
	"currency"      TEXT NOT NULL DEFAULT "EUR",
	PRIMARY KEY("instanceType", "region", "metro")
);

/* ------------------------------------------------------------------ */
/* Block Storage                                                      */
/* ------------------------------------------------------------------ */
/* STACKIT Block Storage offerings: capacity volumes / backups        */
/* (priced per GB/hour) and fixed performance classes (per disk/hour).*/
/* One row per storage class + region + availability (single/multi AZ).*/
DROP TABLE IF EXISTS "block-storage";
CREATE TABLE "block-storage" (
	"class"        TEXT NOT NULL DEFAULT "",   /* Storage class, i.e.: storage_premium_perf0, capacity, backup */
	"region"       TEXT NOT NULL DEFAULT "",   /* -> regions.region */
	"metro"        INTEGER NOT NULL DEFAULT "0", /* 1 = Multi-AZ (region code with '-m'), 0 = Single-AZ */
	"name"         TEXT NOT NULL DEFAULT "",   /* Human readable name, i.e.: Premium-Performance 0 */
	"storageType"  TEXT NOT NULL DEFAULT "",   /* attribute.type: capacity, performance */
	"storageKind"  TEXT NOT NULL DEFAULT "",   /* attribute.storage: volume, backup, backup-incremental */
	"billingUnit"  TEXT NOT NULL DEFAULT "",   /* unitBilling, i.e.: per GB/hour, per disk/hour */
	"maxIops"      INTEGER NOT NULL DEFAULT "0", /* Max IO operations per second (performance classes) */
	"maxThroughputMb" INTEGER NOT NULL DEFAULT "0", /* Max throughput in MB/s (performance classes) */
	"sku"          TEXT NOT NULL DEFAULT "",   /* STACKIT SKU */
	"id"           TEXT NOT NULL DEFAULT "",   /* STACKIT internal id */
	"maturity"     TEXT NOT NULL DEFAULT "",   /* maturityModelState, i.e.: ga, beta */
	"deprecated"   INTEGER NOT NULL DEFAULT "0", /* 1 = deprecated */
	"priceHour"    REAL DEFAULT "0.0",         /* Price per hour (EUR), per GB or per disk depending on type */
	"priceMonth"   REAL DEFAULT "0.0",         /* Price per month (EUR) */
	"currency"     TEXT NOT NULL DEFAULT "EUR",
	PRIMARY KEY("class", "region", "metro")
);

/* Index */
CREATE INDEX IF NOT EXISTS "instance-prices-region-index" ON "instance-prices"(region);
CREATE INDEX IF NOT EXISTS "instance-prices-type-index"   ON "instance-prices"(instanceType);
CREATE INDEX IF NOT EXISTS "block-storage-region-index"   ON "block-storage"(region);
