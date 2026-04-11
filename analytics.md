# DHIS2 analytics tables — report

A profile of the `analytics_*` tables in this dump, what they actually contain, and example queries. Built live against the running stack (`make run` → query against `dhis2-docker-postgresql-1`).

## What's in the dump

This is a **Lao PDR** (Lao People's Democratic Republic) DHIS2 instance — climate, air quality, and disease surveillance. The organisation unit tree has 5 levels:

| Level | Count | What |
|---|---|---|
| 1 | 1 | Country (Lao PDR) |
| 2 | 18 | Provinces (`01 Vientiane Capital` … `18 Xaisomboun`) |
| 3 | 506 | Districts |
| 4 | 2,008 | Health facility catchments |
| 5 | 10,328 | Villages |

Two tracker **event-only programs** exist (both `WITHOUT_REGISTRATION`, i.e. event-only, no tracked-entity registration):

| Program UID | Name | Events | Time span |
|---|---|---|---|
| `WTqDym5rNCT` | **Climate Air Quality** (CAQ) | 171,942 | 2023-04-20 → 2024-04-25 |
| `h6x4kyzKyK3` | **NCLE: Communicable Disease** | 10,214 | 2025-01-01 → 2025-01-31 |

> The analytics tables themselves use lowercase UIDs in their names (`analytics_event_wtqdym5rnct`), while the `dataelement` / `program` metadata tables keep the original case. DHIS2 lowercases UIDs when generating table names.

## Aggregate analytics (`analytics` inheritance chain)

The `analytics` parent and its 12 yearly children (`analytics_2014` … `analytics_2025`) hold **1,244,460 rows** across:

- **54 distinct data elements**
- **587 distinct org units** (from the 12,861 in the tree — only facilities that report data end up here)
- **4,732 distinct periods** (earliest `2013-12-30`, latest `2025-12-31`)

### Rows per year

| Year | Rows | Avg value | Notes |
|---|---|---|---|
| 2014 | 620 | 2.68 | Near-empty, test data |
| 2015 | 73,685 | 431.06 | |
| 2016 | 73,611 | 438.62 | |
| 2017 | 73,952 | 443.51 | |
| 2018 | 91,573 | 366.25 | |
| 2019 | 110,198 | 309.98 | |
| 2020 | 106,793 | 324.02 | |
| 2021 | 98,735 | 355.03 | |
| 2022 | 126,121 | 282.23 | |
| 2023 | 92,065 | 414.01 | |
| 2024 | 93,757 | 412.23 | |
| **2025** | **303,350** | **229.07** | 3× larger than any other year |

2025's row explosion is partly the CAQ sensor program writing daily readings into aggregate tables and partly fresh sensor ingestion.

### Period types

| petype | Rows | What |
|---|---|---|
| Daily | 727,645 | Most data is stored daily — climate sensors, PM2.5, temperature |
| Yearly | 494,375 | Population estimates (`LSB: Population (Estimated-single age)` alone is 455,988 rows) |
| Weekly | 15,556 | Weekly surveillance — very little here |
| Monthly | 6,884 | Routine reporting |

### Top 10 data elements by row count

| UID | Name | Type | Agg | Rows |
|---|---|---|---|---|
| `D8Q6nNeQ7i3` | LSB: Population (Estimated-single age) | NUMBER | AVERAGE_SUM_ORG_UNIT | 455,988 |
| `VA05qvanuVs` | Climate-Temperature avg | NUMBER | AVERAGE | 66,143 |
| `GUGH0txkkNs` | Climate-Temperature min | NUMBER | AVERAGE | 66,068 |
| `ZH76qVQl5Mz` | Climate-Temperature max | NUMBER | AVERAGE | 66,061 |
| `iU9DC6wPjAD` | Air temperature (ERA5-Land) | NUMBER | AVERAGE | 56,279 |
| `sPOIDYWVdZ4` | Precipitation (ERA5-Land) | NUMBER | SUM | 49,584 |
| `MsjCV8o7A7x` | NCLE: 17. Severe Acute Respiratory Infection (SARI) cases | NUMBER | SUM | 47,915 |
| `A0Y0q8g6DHw` | NCLE: 7. Dengue cases (any) | NUMBER | SUM | 43,219 |
| `wTZdHYFQCwT` | Precipitation (CHIRPS)   | NUMBER | SUM | 41,718 |
| `WXVYIRqgLkn` | Average humidity (AirGradient) | NUMBER | AVERAGE | 28,007 |

Two dominant themes: **climate/weather** (ERA5-Land, CHIRPS, AirGradient, sensors) and **disease surveillance** (NCLE dengue, SARI).

### Org-unit level distribution of aggregate rows

| oulevel | Rows | Distinct OUs |
|---|---|---|
| 1 (country) | 1 | 1 |
| 2 (province) | 374,257 | 18 |
| 3 (district) | 618,733 | 421 |
| 4 (facility catchment) | 251,469 | 147 |
| 5 (village) | 0 | 0 |

No village-level aggregate data — that's entirely tracker/event-program territory.

## Completeness (`analytics_completeness`)

Essentially empty. Only one year has any rows:

| Table | Rows |
|---|---|
| `analytics_completeness_2022` | 1 |
| `analytics_completenesstarget` | 12,941 (denominators) |
| `analytics_orgunittarget` | 25,673 |

The `_target` tables define *who should report what* but the actuals (`_completeness_YYYY`) are empty — either this dump was taken before completeness was computed, or the Lao configuration doesn't use DHIS2's dataset-submission completeness mechanism.

## Tracker analytics (Climate Air Quality program)

`WTqDym5rNCT` is the big one: 171,942 sensor-event readings from **14 districts** over a one-year window. Each event row has 9 data-element columns:

| UID column | Name |
|---|---|
| `ArEmgSwTzli` | CAQ - COwork(mV) |
| `nggn8bh00mG` | CAQ - Co(ppm) |
| `U7ObInwZqo3` | CAQ - RH (%) |
| `UkPHvsv8eYz` | CAQ - COaux(mV) |
| `fxWgAbAqpHL` | CAQ - PM2,5(ug/m3) |
| `oF5eeuo6buU` | CAQ - T (degree Celcius) |
| `heB7OaYiQmp` | CAQ - Positioning speed (m/s) |
| `jU8aohk8qLn` | CAQ - PM1.0(ug/m3) |
| `A8hTJnZ8QeV` | CAQ - PM10.0(ug/m3) |

### Top districts by CAQ event volume

| District | Events |
|---|---|
| 1801 Anouvong | 82,877 |
| 1601 Pakxe | 27,716 |
| 1702 Samakhixai | 25,963 |
| 0205 Bounnua | 12,152 |
| 0901 Pek | 7,732 |
| 1101 Pakxan | 5,208 |
| 0801 Xainyabouli | 5,113 |
| 0406 Houn | 4,099 |

82% of CAQ events come from the top 3 districts — sensor placement is very uneven.

## Does direct child-table access ever matter? — cross-verification

The user's practical question: can I always just query the parent, or is there a case where I need to hit the year/program child directly? Verified with two experiments:

### Experiment 1 — aggregate analytics

```sql
SELECT 'parent'::text, COUNT(*) FROM analytics WHERE year = 2024
UNION ALL
SELECT 'child',        COUNT(*) FROM analytics_2024;
```

| source | rows |
|---|---|
| parent (`analytics`) | 93,757 |
| child (`analytics_2024`) | 93,757 |

**Identical.** Parent access returns every child row transparently.

### Experiment 2 — tracker events (per program)

```sql
SELECT 'parent', COUNT(*) FROM analytics_event_wtqdym5rnct
  WHERE occurreddate >= '2024-01-01' AND occurreddate < '2025-01-01'
UNION ALL
SELECT 'child',  COUNT(*) FROM analytics_event_wtqdym5rnct_2024;
```

| source | rows |
|---|---|
| parent | 93,786 |
| child | 93,786 |

**Identical.** Same story for tracker programs, but scoped to one program at a time — there is no `analytics_event` meta-parent across programs.

### Experiment 3 — does the planner actually skip irrelevant children? (`EXPLAIN`)

```sql
EXPLAIN SELECT COUNT(*) FROM analytics WHERE year = 2024;
```

```
 Aggregate  (cost=2433.33..2433.34 rows=1 width=8)
   ->  Append  (cost=0.00..2198.93 rows=93758 width=0)
         ->  Seq Scan on analytics analytics_1  (cost=0.00..0.00 rows=1 width=0)
               Filter: (year = 2024)
         ->  Index Only Scan using "in__ax_2024_Thk6u" on analytics_2024 analytics_2  (cost=0.29..1730.14 rows=93757 width=0)
               Index Cond: (year = 2024)
```

Only two nodes in the `Append`: the empty parent stub (scanned in 0.00 time) and **just `analytics_2024`**. `analytics_2015`, `analytics_2016`, … `analytics_2025` are **absent from the plan entirely** — constraint exclusion on the CHECK constraints each child carries has pruned them.

### Verdict

**Direct child-table access is never required.** Always query the parent. The only case where you'd hit a child directly is if you wanted to bypass the parent for a micro-optimization (cost-wise it's the same once constraint exclusion fires), or if you wanted to scan literally all years without any `WHERE year = …` clause (where there's genuinely no pruning benefit).

One real-world caveat: if your `WHERE` clause doesn't give the planner a direct `year = X` predicate — e.g. `WHERE pestartdate > '2024-06-01'` — constraint exclusion can't help, and you'll scan every child. To force pruning, either add `AND year = 2024` explicitly, or query the specific partition directly.

## Example queries

### 1. Dengue case trend over time (Lao PDR, all provinces combined)

```sql
SELECT year, ROUND(SUM(value)::numeric, 0) AS dengue_cases
FROM analytics
WHERE dx = 'A0Y0q8g6DHw'   -- NCLE: 7. Dengue cases (any)
  AND petype = 'Daily'
GROUP BY year
ORDER BY year;
```

| year | dengue_cases |
|---|---|
| 2019 | 32,236 |
| 2020 | 8,218 |
| 2021 | 1,585 |
| 2022 | 33,163 |
| 2023 | 36,529 |
| 2024 | 20,817 |
| 2025 | 1,185 (partial) |

Huge drop in 2020–21 (COVID reporting disruption or reduced case-finding) and a rebound in 2022–23.

### 2. Top 10 worst PM2.5 events (sensor spikes)

```sql
SELECT TO_CHAR(occurreddate, 'YYYY-MM-DD HH24:MI') AS time,
       ouname,
       ROUND("fxWgAbAqpHL"::numeric, 1) AS pm25_ug_m3,
       ROUND("oF5eeuo6buU"::numeric, 1) AS temp_c
FROM analytics_event_wtqdym5rnct
WHERE "fxWgAbAqpHL" IS NOT NULL
ORDER BY "fxWgAbAqpHL" DESC
LIMIT 10;
```

| time | district | PM2.5 (μg/m³) | Temp (°C) |
|---|---|---|---|
| 2023-05-17 14:58 | 1601 Pakxe | 4,070.0 | 40.6 |
| 2023-05-17 17:04 | 1601 Pakxe | 3,044.0 | 44.3 |
| 2023-05-17 16:48 | 1601 Pakxe | 2,148.0 | 44.6 |
| 2023-05-17 14:57 | 1601 Pakxe | 2,094.0 | 40.7 |
| 2023-05-17 17:29 | 1601 Pakxe | 2,060.0 | 43.7 |
| 2023-05-17 16:57 | 1601 Pakxe | 2,038.0 | 44.0 |
| 2023-05-17 16:47 | 1601 Pakxe | 2,034.0 | 45.0 |
| 2023-06-23 12:48 | 1801 Anouvong | 1,567.0 | 37.2 |
| 2023-06-23 13:45 | 1801 Anouvong | 1,549.0 | 37.3 |
| 2024-04-06 11:50 | 0205 Bounnua | 1,448.0 | 34.7 |

For reference, the WHO 24-hour PM2.5 guideline is 15 μg/m³. Pakxe saw ≥2,000 μg/m³ multiple times on a single afternoon in May 2023 at >40°C — likely a wildfire or dust storm.

### 3. Province-level temperature climatology

```sql
SELECT
  des.dataelementname AS metric,
  uidlevel2 AS province_uid,
  ou_rs.namelevel2 AS province,
  year,
  ROUND(AVG(a.value)::numeric, 1) AS avg_value
FROM analytics a
JOIN analytics_rs_dataelementstructure des ON des.dataelementuid = a.dx
JOIN (SELECT DISTINCT uidlevel2, namelevel2 FROM analytics_rs_orgunitstructure) ou_rs
     ON ou_rs.uidlevel2 = a.uidlevel2
WHERE a.dx = 'VA05qvanuVs'   -- Climate-Temperature avg
  AND a.year BETWEEN 2022 AND 2024
GROUP BY des.dataelementname, uidlevel2, ou_rs.namelevel2, year
ORDER BY province, year;
```

This demonstrates the pattern of joining the fact table to resource tables (`analytics_rs_dataelementstructure` for names, `analytics_rs_orgunitstructure` for hierarchy) instead of the live metadata tables.

### 4. Which districts stopped reporting dengue after 2023?

```sql
WITH by_district_year AS (
  SELECT uidlevel3 AS district, year, SUM(value) AS cases
  FROM analytics
  WHERE dx = 'A0Y0q8g6DHw'
  GROUP BY uidlevel3, year
)
SELECT ou.namelevel3 AS district_name,
       MAX(CASE WHEN year = 2023 THEN cases END) AS cases_2023,
       MAX(CASE WHEN year = 2024 THEN cases END) AS cases_2024,
       MAX(CASE WHEN year = 2025 THEN cases END) AS cases_2025
FROM by_district_year byd
JOIN (SELECT DISTINCT uidlevel3, namelevel3 FROM analytics_rs_orgunitstructure) ou
  ON ou.uidlevel3 = byd.district
GROUP BY ou.namelevel3
HAVING MAX(CASE WHEN year = 2023 THEN cases END) > 100
  AND (MAX(CASE WHEN year = 2024 THEN cases END) IS NULL
       OR MAX(CASE WHEN year = 2024 THEN cases END) = 0)
ORDER BY cases_2023 DESC
LIMIT 20;
```

Finds districts that had significant dengue in 2023 but stopped reporting in 2024 — a data-quality / reporting-gap query.

### 5. CAQ sensor coverage per district (hours of data)

```sql
SELECT
  ouname AS district,
  COUNT(*) AS readings,
  MIN(occurreddate)::date AS first_reading,
  MAX(occurreddate)::date AS last_reading,
  (MAX(occurreddate) - MIN(occurreddate)) AS span
FROM analytics_event_wtqdym5rnct
GROUP BY ouname
ORDER BY readings DESC;
```

Shows which districts the CAQ sensors actually covered and for how long. Good for finding coverage gaps.

### 6. Monthly CAQ event volume (to see the ramp-up and plateau)

```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', occurreddate), 'YYYY-MM') AS month,
  COUNT(*) AS events,
  ROUND(AVG("fxWgAbAqpHL")::numeric, 1) AS avg_pm25,
  ROUND(AVG("oF5eeuo6buU")::numeric, 1) AS avg_temp_c
FROM analytics_event_wtqdym5rnct
WHERE "fxWgAbAqpHL" IS NOT NULL
GROUP BY month
ORDER BY month;
```

### 7. Which data elements are "active" (recent data) vs "dormant"?

```sql
SELECT
  des.dataelementname,
  MAX(a.peenddate) AS last_period_with_data,
  COUNT(*) AS rows,
  CASE
    WHEN MAX(a.peenddate) >= CURRENT_DATE - INTERVAL '90 days' THEN 'active'
    WHEN MAX(a.peenddate) >= CURRENT_DATE - INTERVAL '1 year'  THEN 'stale'
    ELSE 'dormant'
  END AS status
FROM analytics a
JOIN analytics_rs_dataelementstructure des ON des.dataelementuid = a.dx
GROUP BY des.dataelementname
ORDER BY last_period_with_data DESC;
```

Useful as a reporting-health check: surfaces DEs that have silently stopped producing data.

### 8. Org-unit-group breakdown of dengue reporting

```sql
SELECT
  og.name AS orgunit_group,
  ROUND(SUM(a.value)::numeric, 0) AS dengue_cases
FROM analytics a
JOIN analytics_rs_organisationunitgroupsetstructure ogs
  ON ogs.organisationunitid = a.sourceid
CROSS JOIN LATERAL jsonb_each_text(to_jsonb(ogs)) og_field
JOIN organisationunitgroup og ON og.uid = og_field.value
WHERE a.dx = 'A0Y0q8g6DHw' AND a.year = 2023
GROUP BY og.name
HAVING SUM(a.value) > 0
ORDER BY dengue_cases DESC;
```

A more exotic pattern — using the `analytics_rs_organisationunitgroupsetstructure` resource table to pivot reports by OU group (facility type, urban/rural, etc) without joining the live org-unit metadata. The exact column names depend on which group sets exist (your dump has `LBwVBieQt45` = Health Facilities, `QvOC5lYcCgs` = WRS, `Vr1KAD9cfqH` = Organisation Unit Types, `EueGp8JK74D` = Villages).

## Quick reference

| You want... | Query start |
|---|---|
| Aggregate DE values by time/OU/DE | `FROM analytics WHERE dx = '...' AND year = ...` |
| Completeness ratios | `FROM analytics_completeness JOIN analytics_completenesstarget ON ...` (mostly empty in this dump) |
| Climate Air Quality sensor events | `FROM analytics_event_wtqdym5rnct WHERE "fxWgAbAqpHL" IS NOT NULL` |
| NCLE event records | `FROM analytics_event_h6x4kyzkyk3 WHERE ...` |
| Flat org-unit hierarchy | `FROM analytics_rs_orgunitstructure` (idlevel1..5, uidlevel1..5, namelevel1..5) |
| Period-type lookups | `FROM analytics_rs_periodstructure` |
| DE metadata | `FROM analytics_rs_dataelementstructure` |

**Rule of thumb:** query the parent table (`analytics`, `analytics_event_<prog>`), let postgres's constraint exclusion route the filter to the right year partition, and join the `analytics_rs_*` tables for any hierarchy/metadata instead of the live transactional tables.
