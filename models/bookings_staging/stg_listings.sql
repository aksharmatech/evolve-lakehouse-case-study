{{ config(materialized='table') }}

/*
 * Staging model for listings data
 *
 * Purpose: Cleans and standardizes raw listing data by trimming whitespace and casting to appropriate data types
 *
 * Source: raw.listings
 * Grain: One row per listing
 *
 * Key transformations:
 * - Trims whitespace from all string fields
 * - Casts listing_id to integer
 * - Casts dates to date type
 */

select
    trim(listing_id)::int as listing_id,                        -- Unique identifier for the listing
    trim(listing_activation_date)::date as listing_activation_date,  -- Date when listing became active
    trim(listing_resign_date)::date as listing_resign_date          -- Date when listing was deactivated (null if still active)
from
    {{source('raw','listings')}}
    