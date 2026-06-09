/*
 * Hand maintained, additional instance type information.
 *
 * The STACKIT price API (skus) only exposes a coarse "hardware" field
 * (Intel / AMD / ARM / GPU) plus vCPU and RAM. Everything below is
 * curated knowledge that is NOT part of the API and can be extended
 * here over time (CPU architecture, vendor, model, base clock, GPU model...).
 *
 * This file is applied AFTER import.pl, so it only UPDATEs existing rows.
 * Matching is done by instance family prefix to keep it compact.
 *
 */

/* ---- End of Life ------------------------------------------------ */
/*
 * Sources:
 *  https://docs.stackit.cloud/products/compute-engine/server/release-notes/#stackit-server---end-of-life-for-first-generation-intel-machine-types-on-01-october-2025
 */

/* Remove the instance types ... */
DELETE FROM "instance-types"
WHERE "instanceFamily" IN ('t1', 's1', 'c1', 'g1', 'm1', 'b1');

/* ... and their prices (avoid orphaned rows in instance-prices). */
DELETE FROM "instance-prices"
WHERE "instanceType" NOT IN (SELECT "instanceType" FROM "instance-types");

/* ---- CPU/GPU hardware -------------------------------------------- */
/*
 * Sources:
 * https://docs.stackit.cloud/products/compute-engine/server/basics/machine-types/#machine-type-versions
 */
UPDATE "instance-types" SET "cpuModel" = 'Intel Broadwell', "cpuBaseClockGhz" = 2.0 WHERE "instanceFamily" = 'c1';
UPDATE "instance-types" SET "cpuModel" = 'Intel Ice Lake', "cpuBaseClockGhz" = 2.3 WHERE "instanceFamily" IN ('t2i', 'c2i', 'g2i', 'm2i', 'b2i');
UPDATE "instance-types" SET "cpuModel" = 'Intel Emerald Rapids 8580', "cpuBaseClockGhz" = 2.0 WHERE "instanceFamily" IN ('t3i', 's3i', 'c3i');
UPDATE "instance-types" SET "cpuModel" = 'Intel Emerald Rapids 6548Y+', "cpuBaseClockGhz" = 2.5 WHERE "instanceFamily" IN ('g3i', 'm3i', 'b3i');
UPDATE "instance-types" SET "cpuModel" = 'AMD EPYC Rome or Milan', "cpuBaseClockGhz" = 2.0 WHERE "instanceFamily" IN ('s1a', 'c1a', 'g1a', 'b1a');
UPDATE "instance-types" SET "cpuModel" = 'AMD EPYC Milan', "cpuBaseClockGhz" = 2.0 WHERE "instanceFamily" = 'm1a';
UPDATE "instance-types" SET "cpuModel" = 'AMD EPYC Bergamo 9754', "cpuBaseClockGhz" = 2.25 WHERE "instanceFamily" IN ('c2a', 'g2a');
UPDATE "instance-types" SET "cpuModel" = 'AMD EPYC Genoa 9654', "cpuBaseClockGhz" = 2.4 WHERE "instanceFamily" = 'm2a';
UPDATE "instance-types" SET "cpuModel" = 'AMD EPYC Genoa 9534', "cpuBaseClockGhz" = 2.4 WHERE "instanceFamily" = 'b2a';
UPDATE "instance-types" SET "cpuModel" = 'Ampere Altra Max M128-30', "cpuBaseClockGhz" = 3.0 WHERE "instanceFamily" = 'g1r';
UPDATE "instance-types" SET "cpuModel" = 'Intel Ice Lake', "hardware" = 'Intel', "gpuVendor" = 'NVIDIA', "gpuModel" = 'NVIDIA A100', "gpuMemoryGb" = 80 WHERE "instanceFamily" = 'n1';
UPDATE "instance-types" SET "cpuModel" = 'Intel Sapphire Rapids', "hardware" = 'Intel', "gpuVendor" = 'NVIDIA', "gpuModel" = 'NVIDIA L40S', "gpuMemoryGb" = 48 WHERE "instanceFamily" = 'n2';
UPDATE "instance-types" SET "cpuModel" = 'Intel Sapphire Rapids', "hardware" = 'Intel', "gpuVendor" = 'NVIDIA', "gpuModel" = 'NVIDIA H100 HGX', "gpuMemoryGb" = 80 WHERE "instanceFamily" = 'n3';

/* ---- CPU architecture by reported hardware ----------------------- */
UPDATE "instance-types" SET "cpuVendor" = 'Intel',  "cpuArchitecture" = 'x86_64' WHERE "hardware" = 'Intel';
UPDATE "instance-types" SET "cpuVendor" = 'AMD',    "cpuArchitecture" = 'x86_64' WHERE "hardware" = 'AMD';
UPDATE "instance-types" SET "cpuVendor" = 'Ampere', "cpuArchitecture" = 'arm64'  WHERE "hardware" = 'ARM';

/* ---- Local disk -------------------------------------------------- */
/*
 * Local disk size is not available via the API. Set "localDiskGb" per
 * flavor (or family) below.
 *
 * Sources:
 * https://docs.stackit.cloud/products/compute-engine/server/basics/machine-types/#machine-types-without-cpu-overprovisioning-amd-gen2
 * https://docs.stackit.cloud/products/compute-engine/server/basics/machine-types/#machine-types-with-nvidia-gpus-and-without-cpu-overprovisioning
 */

UPDATE "instance-types" SET "localDiskGb" = 500  WHERE "instanceType" = 'c2a.30d';
UPDATE "instance-types" SET "localDiskGb" = 1000  WHERE "instanceType" = 'c2a.60d';
UPDATE "instance-types" SET "localDiskGb" = 1700  WHERE "instanceType" = 'c2a.120d';
UPDATE "instance-types" SET "localDiskGb" = 3400  WHERE "instanceType" = 'c2a.240d';

UPDATE "instance-types" SET "localDiskGb" = 500  WHERE "instanceType" = 'g2a.30d';
UPDATE "instance-types" SET "localDiskGb" = 1000  WHERE "instanceType" = 'g2a.60d';
UPDATE "instance-types" SET "localDiskGb" = 1700  WHERE "instanceType" = 'g2a.120d';

UPDATE "instance-types" SET "localDiskGb" = 1536  WHERE "instanceType" = 'n3.104d.g8';

/*
 * Keep the "localDisk" flag in sync with "localDiskGb".
 * Anything with a size > 0 is flagged as having a local disk.
 * (Leave this at the end so it picks up all of the updates above.)
 */
UPDATE "instance-types" SET "localDisk" = 1 WHERE "localDiskGb" > 0;
UPDATE "instance-types" SET "localDisk" = 0 WHERE "localDiskGb" <= 0;
