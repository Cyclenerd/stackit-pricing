# Build

This project generates a static website from the STACKIT price list.
Ready to tweak and test this webapp locally? Follow these instructions.

## Requirements

* curl (`curl`)
* SQLite3 (`sqlite3`)
* Perl 5 (`perl`)
* Perl modules:
	* [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)
	* [JSON::XS](https://metacpan.org/pod/JSON::XS)
	* [plackup](https://metacpan.org/dist/Plack/view/script/plackup) (only to preview locally)
	* [Template::Toolkit](https://metacpan.org/pod/Template::Toolkit)
	* [Text::CSV](https://metacpan.org/pod/Text::CSV) (only used by the export)

<details>
<summary><b>Debian/Ubuntu</b></summary>

```bash
sudo apt update
sudo apt install \
	curl \
	libdbd-sqlite3-perl \
	libjson-xs-perl \
	libplack-perl \
	libtemplate-perl \
	libtext-csv-perl \
	sqlite3
```
</details>

<details>
<summary><b>macOS</b></summary>

```bash
brew install cpanminus curl perl pkg-config sqlite3
cpanm --installdeps .
```
</details>

## One-shot build

The whole pipeline (download, import, export, generate) is wrapped in `build.sh`:

```bash
cd build
bash build.sh
```

Skip the download and reuse the existing `pricing.json`:

```bash
SKIP_DOWNLOAD=1 bash build.sh
```

## Step by step

### 1. Download the price list

```bash
curl "https://pim.api.stackit.cloud/v1/skus" -o pricing.json
```

### 2. Create the database

```bash
sqlite3 stackit.db < create.sql
```

### 3. Seed regions

```bash
sqlite3 stackit.db < regions.sql
```

### 4. Import pricing

```bash
perl import.pl < pricing.json
```

This fills two tables:

* `instance-types` — one row per flavor (e.g. `c1.1`), region independent facts
* `instance-prices` — one row per flavor + region + availability (Single/Multi-AZ)
* `block-storage` — one row per storage class + region + availability (capacity/backup billed per GB, performance classes billed per disk)

### 5. Add extra instance type information (optional, curated)

The STACKIT API does not expose exact CPU architecture, CPU/GPU model, etc.
Add them via SQL in `instance-types-extra.sql` and apply:

```bash
sqlite3 stackit.db < instance-types-extra.sql
```

Example — add a CPU model and base clock for a whole family:

```sql
UPDATE "instance-types"
  SET "cpuModel" = 'Intel Xeon Sapphire Rapids', "cpuBaseClockGhz" = 2.0
  WHERE "instanceFamily" = 'c3i';
```

Example — add a GPU model:

```sql
UPDATE "instance-types"
  SET "gpuModel" = 'NVIDIA H100', "gpuMemoryGb" = 80
  WHERE "instanceType" = 'n3.14d.g1';
```

### 6. Export CSV + SQL

```bash
bash export.sh
```

### 7. Generate the website

```bash
perl web.pl
```

## Preview locally

```bash
plackup --host "127.0.0.1" --port "8080"
```

Then open <http://127.0.0.1:8080/>.

## Data model notes

STACKIT flavor naming (best effort):

```
<type><gen>[vendor].<size>[d][.g<gpus>]
  type:   b/t=basic/tiny, c=compute, g=general, m=memory, s=storage, n=gpu, u=ultra-memory
  vendor: i=Intel, a=AMD, r=ARM (absent on older generations)
  d:      flavor ships with local NVMe disk
  .gN:    number of GPUs (GPU servers only)
```

Regions ending with `-m` (metro) are Multi-AZ. In the database this is stored as
the `metro` flag on each price row, so the base region code (`eu01`, `eu02`) stays clean.
