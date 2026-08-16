# Meridian Pay — Data Warehousing Project (Work in Progress)

## Overview

Building a data warehouse from scratch for a fictional global card-payments
business, modeled loosely on how a company like Mastercard operates. The
end goal: a warehouse that can answer a defined set of business KPIs
spanning network operations, revenue, ecosystem growth, and platform
health — roughly 10 KPIs across those four categories.

**Current stage: raw data intake(bronze).** The dimensional model — how many
fact/dimension tables, what grain, what gets conformed vs. dropped — isn't
designed yet. That comes after profiling and cleaning the source data
below.

## What's in `/data/raw` right now

Raw extracts simulating several different upstream systems, each with its
own format and quirks:

| File | Simulated source system | Format |
|---|---|---|
| `src_card_master_system_A.csv` | Card issuing platform | CSV |
| `src_card_status_feed.tsv` | Card ops/status monitoring | Tab-delimited |
| `src_merchant_master.csv` | Merchant onboarding/KYC | CSV |
| `src_merchant_incremental.csv` | Same system, weekly delta | CSV |
| `src_country_reference.csv` | Manually-maintained reference table | CSV |
| `src_transactions_legacy_2024H1.csv` | Transaction processor, pre-migration | CSV |
| `src_transactions_2024H2_2025.csv` | Transaction processor, post-migration | CSV |
| `src_revenue_emea.csv` | EMEA finance reporting tool | CSV, `;` delimited |
| `src_revenue_amer_apac.csv` | Americas/APAC finance reporting tool | CSV |
| `src_company_financials.xlsx` | Finance monthly P&L export | Excel |
| `src_api_logs.jsonl` | API gateway logging pipeline | JSON Lines |
| `src_system_incidents.csv` | Infra monitoring/incident system | CSV |

## Known issues so far

Inconsistent casing and stray whitespace in text fields; several different
date/datetime formats across files (and sometimes within the same column);
boolean flags encoded differently depending on source; currency values
mixed between plain numbers and formatted strings; duplicate rows; some
foreign keys with no matching record elsewhere; a couple of source systems
that disagree with each other on the same entity (e.g. two card-status
sources, two merchant feeds); one dataset that isn't pre-aggregated at all
(incident-level, not daily uptime) and one that's pivoted wide instead of
normalized.

## Roadmap
BRONZE
- [x] Create table for each file
- [x] Import the raw data from localfiles, as-it-is, to the databasetables
- [x] Create "stored procedure" for importing any new data from the source files
SILVER
- [x] Profile each source file (nulls, duplicates, distinct values, key coverage)
- [x] Clean & conform (standardize types/formats, resolve cross-source conflicts)
- [x] Create "stored procedure" for importing new data from the bronze tables
GOLD
- [ ] Design the dimensional model based on findings + the KPI requirements
- [ ] Build the ETL pipeline and load into the warehouse
ANALYSIS
- [ ] Write the KPI queries
- [ ] (stretch) BI dashboard layer

## Tech stack

- SQL Server (target warehouse)
- Power BI(stretch)

## Author

Pankaj Rathod — [GitHub](https://github.com/pankajdineshrathod)
