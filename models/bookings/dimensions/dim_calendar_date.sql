{{ config(materialized='table') }}

/*
 * Calendar date dimension table
 *
 * Purpose: Generates a comprehensive calendar dimension with date attributes for analysis and reporting
 *
 * Source: Derived from stg_listings (using min activation date as start)
 * Grain: One row per calendar date from earliest listing activation to current date
 *
 * Key features:
 * - Dynamically generates date range based on data
 * - Provides hierarchical date attributes (day, week, month, quarter, year)
 * - Includes business-relevant flags (e.g., is_weekend)
 */

with
    -- Determine the date range to generate (from earliest listing to today)
    c_date_range as (
        select
            min(listing_activation_date) as start_date,
            current_date() as end_date,
            DATEDIFF(DAY, start_date, end_date) as number_of_days
        from
            {{ref("stg_listings")}}
    ),
    -- Generate an array of integers to create date series
    c_date_series_integers as (
        select
            array_generate_range(0, number_of_days+1, 1) as days
        from
            c_date_range
    )
    select
        dateadd(DAY,dd.value, dr.start_date) as calendar_date,
        to_char(calendar_date,'YYYYMMDD')::int as date_key,        -- Surrogate key in YYYYMMDD format

        -- Day-level attributes
        dayofweek(calendar_date) as day_of_week,                   -- 0 (Sunday) to 6 (Saturday)
        dayname(calendar_date) as day_name,                        -- Full name of day (e.g., 'Monday')
        day(calendar_date) as day_of_month,                        -- Day number in month (1-31)
        dayofyear(calendar_date) as day_of_year,                   -- Day number in year (1-365/366)
        day_name in ('Sat','Sun') as is_weekend,                   -- Flag for weekend days

        -- Week-level attributes
        weekofyear(calendar_date) as week_of_year,                 -- Week number in year (1-52/53)
        yearofweek(calendar_date) as year_of_week,                 -- Year associated with the week

        -- Month-level attributes
        month(calendar_date) as month_of_year,                     -- Month number (1-12)
        monthname(calendar_date) as month_name,                    -- Full name of month (e.g., 'January')

        -- Quarter-level attributes
        quarter(calendar_date) as quarter_of_year,                 -- Quarter number (1-4)
        'Q' || quarter_of_year as quarter_name,                    -- Quarter label (e.g., 'Q1')

        -- Year-level attributes
        year(calendar_date) as year                                -- Calendar year (e.g., 2024)
    from
        c_date_range dr
    left join
        c_date_series_integers ds,
    lateral flatten(input => ds.days) as dd                        -- Flatten array to create one row per date