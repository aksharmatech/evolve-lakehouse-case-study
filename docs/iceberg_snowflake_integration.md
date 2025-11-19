# Apache Iceberg Overview

## What is an Apache Iceberg table?

Apache Iceberg is an open table format that adds a metadata layer on top of data files (Parquet/ORC) in object storage, providing table-like capabilities with ACID transactions, schema evolution, and snapshot management.

## Why use Iceberg instead of plain Parquet on S3?

- **ACID transactions** prevent data corruption during concurrent reads/writes
- **Schema evolution** allows column changes without rewriting data
- **Time travel** enables querying historical data snapshots
- **Efficient querying** through metadata-based file pruning (skips irrelevant files)
- **Hidden partitioning** handles partition changes automatically
- **Multi-engine support** works across Spark, Snowflake, Trino, Athena without vendor lock-in

Essentially, Iceberg transforms plain files into a reliable, production-grade data warehouse table.


## How does dbt create and manage Iceberg tables in this architecture?

- dbt uses the **dbt-glue adapter** which runs transformations on **AWS Glue's Spark engine**
- **Table materializations**: Use `CREATE TABLE ... USING iceberg` or `INSERT OVERWRITE` for full refreshes
- **Incremental materializations**: Use `MERGE INTO` for upserts or `INSERT INTO` for appends (leveraging Iceberg's ACID transactions)
- **View materializations**: Create standard SQL views on top of Iceberg tables
- dbt manages the entire lifecycle through SQL/Spark commands executed via Glue jobs
- **AWS Glue Data Catalog** stores all Iceberg table metadata

## How can Snowflake query Iceberg tables stored in S3 without copying data into Snowflake-managed storage?
[Answer provided here](./architecture.md#zero-copy-query-architecture)


## Migration Risk: From dbt-Snowflake to Lakehouse Design

**Key Risk**: 
Query performance degradation due to Snowflake's mature query optimizer and automatic clustering being replaced by external Iceberg tables that require manual optimization and have slower cold-start performance.

**Mitigation Strategy**: 
Implement a hybrid approach where hot data (last 3-6 months) remains in native Snowflake tables for performance-critical queries, while historical data uses Iceberg external tables for cost savings. 
Additionally, establish rigorous Iceberg table maintenance routines including regular compaction, optimal file sizing (128MB-1GB), and proper partitioning strategies to maintain query performance comparable to native Snowflake tables.

