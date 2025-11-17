
<h1 align="center">Evolve Lakehouse Data Engineering Case Study</h1>

<p align="center">
  <img src="evolve-banner.png" alt="Evolve" width="600"/>
</p>

A take-home data engineering project simulating how Evolve designs analytical lakehouse pipelines using Iceberg, dbt, and Snowflake.

---

## Welcome to the Evolve Data Engineering Case Study

Thank you for taking the time to participate.  
This challenge is designed to reflect real data problems we solve at Evolve.

Evolve manages homes listed on short-term vacation rental platforms such as Airbnb.  
As part of this, we closely track:

- **Occupancy** — how often guests book our properties vs. how often owners block nights

A core metric we monitor is:

> **Available Occupancy % = Guest Occupancy / Available Nights**

Where:

- **Guest Occupancy** = nights booked by paying guests  
- **Owner Occupancy** = nights blocked by the owner  
- **Available Nights** = total calendar nights minus owner-blocked nights  

Your lakehouse design and dbt modeling should support computing this metric at a property-day and month level and making it easily queryable from Snowflake.

---

## The Process

1. You receive a private GitHub repo containing this scaffold.  
2. You have **up to 5 days** to work asynchronously.  
3. Final interview: **60 minutes total**
   - **20 minutes** — candidate-led walkthrough of your architecture + models  
   - **40 minutes** — deep technical discussion with our engineering team  

The session is informal and collaborative — think of it as reviewing real work together.

---

## Repository Layout

```text
evolve-lakehouse-case-study/
├── README.md
├── data/
│   └── raw/
│       ├── listings.csv
│       ├── bookings.csv
│       └── daily_calendar.csv
├── docs/
│   └── README.md
├── models/
│   ├── README.md
│   ├── staging/
│   └── marts/
└── diagrams/
    └── README.md
```

---

## Challenge Overview

You will design a modern AWS-based lakehouse that enables:

- Ingesting raw rental-platform data into **S3**  
- Managing raw + transformed data as **Apache Iceberg** tables  
- Transforming data with **dbt** (Spark or Trino engine)  
- Allowing **Snowflake** to query Iceberg tables without copying data  
- Supporting analytics on:
  - **Available Occupancy %**
  - Property-day level occupancy metrics

You do **not** need to deploy real infrastructure. Focus on architecture, data modeling, and clarity.

---

## Tasks (Option A – Medium Difficulty)

### 1. Architecture Design (`docs/architecture.md`)

Describe a target-state architecture on AWS that covers:

- How raw CSVs in `data/raw/` would land in an S3 bucket  
- How those files become Iceberg **raw** tables, for example:
  - `raw.listings`
  - `raw.bookings`
  - `raw.daily_calendar`
- How **dbt** (running on Spark/Trino) builds:
  - `staging` layer tables (cleaned, typed, normalized)
  - `marts` layer tables, including a property-day fact model
- How **Snowflake** is configured to:
  - Use an external volume pointing to the Iceberg S3 location  
  - Read Iceberg metadata via a catalog integration (e.g., Glue)  
  - Query curated Iceberg tables without copying data into Snowflake-managed storage
- How analysts can:
  - Compute **Guest Occupancy**, **Available Nights**, and **Available Occupancy %** by listing and month  

Include an architecture diagram saved as `diagrams/architecture.png` and referenced from your doc.

---

### 2. dbt-Style Modeling (`models/`)

You do **not** need to run dbt; just structure the project as if you would.

#### a. `models/schema.yml`

Define a `raw` source with tables:

- `listings`
- `bookings`
- `daily_calendar`

Add tests such as:

- `unique` and `not_null` on keys  
- `relationships` (e.g., `bookings.listing_id` → `listings.listing_id`)  

#### b. Staging Models (`models/staging/`)

Create:

- `stg_listings.sql`
- `stg_bookings.sql`

Expectations:

- Use `{{ source('raw', 'listings') }}` and `{{ source('raw', 'bookings') }}`  
- Cast IDs, numerics, dates, and timestamps to appropriate types  
- Normalize column names to `snake_case`  
- Optionally add helper flags (e.g., guest vs owner bookings)

#### c. Mart Model (`models/marts/fct_property_day.sql`)

Create a **property-day grain** fact table that combines bookings and the daily calendar.

The table should:

- Be at grain **(listing_id, date)**  
- Include:
  - `listing_id`
  - `date`
  - `is_available`
  - `is_occupied` (guest nights)
  - `is_owner_blocked`
  - `price`
  - `daily_revenue`
- Make it possible (via SQL rollups) to compute:
  - Guest Occupancy (sum of occupied guest nights)
  - Available Nights (sum of non-owner-blocked nights)
  - **Available Occupancy %** (Guest Occupancy / Available Nights) by listing and month

You may assume a `date_spine` model exists or explain how you would implement one.

Use comments in the SQL to explain how downstream analysts would use this table.

---

### 3. Iceberg + Snowflake Integration (`docs/iceberg_snowflake_integration.md`)

Create a short write-up answering:

1. What is an Apache Iceberg table and why use it instead of plain Parquet on S3?  
2. How would dbt create and manage Iceberg tables in this architecture (which engine, how materializations map to Iceberg operations)?  
3. How can Snowflake query Iceberg tables stored in S3 without copying data into Snowflake-managed storage?  
4. If Evolve migrated from “dbt in Snowflake over Snowflake tables” to this lakehouse design, what is one key risk and how would you mitigate it?

Keep the answers concise but technically grounded.

---

## Deliverables

Please submit:

- `docs/architecture.md`  
- `docs/iceberg_snowflake_integration.md`  
- All SQL and YAML files under `models/`  
- Any diagrams under `diagrams/`  
- A brief note describing assumptions and trade-offs  

You can return your work as:

- A private GitHub repository, or  
- A zipped version of this repository  

Be prepared to walk through your work during the interview.

---

## Thank You

Thank you for taking the time to complete this case study.  
We look forward to reviewing your work and discussing your approach.
