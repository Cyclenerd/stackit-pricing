# STACKIT Compute Pricing

[![Badge: CI](https://github.com/Cyclenerd/stackit-pricing/actions/workflows/build.yml/badge.svg)](https://github.com/Cyclenerd/stackit-pricing/actions/workflows/build.yml)
[![Badge: GitHub](https://img.shields.io/github/license/cyclenerd/stackit-pricing)](https://github.com/Cyclenerd/stackit-pricing/blob/master/LICENSE)

This webapp helps you compare all **STACKIT Compute Engine** instance types across
all STACKIT regions with ease.
No more hopping between docs – filter, sort, and choose the optimal instance type for your needs.

> [!IMPORTANT]
> This is an unofficial, community-built tool. It is **not** affiliated with,
> endorsed by, or sponsored by STACKIT or Schwarz IT.

## ✨ Features

* All STACKIT Compute Engine instance types (flavors), incl. GPU servers
* Both regions: `eu01` and `eu02`
* Single-AZ and Multi-AZ (metro, region code with `-m`) pricing
* Filter pages by family (Compute, General Purpose, Memory, Tiny, GPU)
  and by hardware (Intel, AMD, ARM)
* Interactive **Instance Picker** (AG Grid) with sortable, filterable columns
* CSV and SQL (SQLite) exports for offline analysis

## 📊 Data source

Pricing is imported from the public STACKIT Price Information Model (PIM) API:

```bash
curl "https://pim.api.stackit.cloud/v1/skus" -o pricing.json
```

Only the `Virtual Machines` product group (Compute Engine + GPU) is used.

The API only exposes coarse hardware info (Intel / AMD / ARM / GPU), vCPU and RAM.
Additional, curated details (CPU architecture, CPU/GPU model, base clock, ...) live
in [`build/instance-types-extra.sql`](./build/instance-types-extra.sql) and can be
extended over time via simple SQL — see [build/README.md](./build/README.md).

## 🏗️ Architecture

Static site generator written in Perl:

```
pricing.json ──> import.pl ──> SQLite (stackit.db) ──> web.pl ──> static HTML
                                   ▲
                  regions.sql ─────┤
       instance-types-extra.sql ───┘
```

Dive into the [build](./build/) folder to see how the data is retrieved, processed,
and integrated.

## ❤️ Contributing

Got a patch that boosts this project?
Get involved by contributing bug fixes and features through pull requests.

* Prep: Please read [how to contribute](./CONTRIBUTING.md).
* Fork it, patch it, and open a Pull Request (PR).

## 📜 License

All files in this repository are under the [Apache License, Version 2.0](./LICENSE) unless noted otherwise.

Please note:

* No warranty
* Not an official STACKIT / Schwarz IT product
* The accuracy of the data is not guaranteed
