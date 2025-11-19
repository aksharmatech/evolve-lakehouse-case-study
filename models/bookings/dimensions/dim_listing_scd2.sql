{{ config(materialized='table') }}

/*
 * Listing dimension table with Slowly Changing Dimension Type 2 (SCD2) implementation
 *
 * Purpose: Tracks historical changes to listings by maintaining separate records for each time period
 *
 * Source: stg_listings
 * Grain: One row per listing per effective period
 *
 * SCD2 Design:
 * - Uses effective_date_from and effective_date_to to define validity periods
 * - Each listing can have multiple rows representing different time periods
 * - Active records have effective_date_to = 99991231 (9999-12-31)
 * - Includes is_active flag for easy filtering of current records
 *
 * Key fields:
 * - listing_key: Surrogate key combining listing_id and activation date
 * - effective_date_from/to: Date range when this version of the listing was/is valid
 */

select
    md5(concat_ws('~', nvl((listing_id)::text,''), nvl((listing_activation_date)::text,''))) as listing_key,  -- Surrogate key (hash of listing_id + activation date)
    listing_id,                                                                                                -- Natural key for the listing
    to_char(listing_activation_date,'YYYYMMDD')::int as effective_date_from,                                 -- Start date of validity period
    to_char(coalesce(listing_resign_date,'9999-12-31'::date),'YYYYMMDD')::int as effective_date_to,         -- End date of validity period (9999-12-31 if still active)
    listing_resign_date is null as is_active,                                                                 -- Flag indicating if this is the current/active record
    100::numeric(20,2) as listing_price                                                                       -- Price per night for the listing
from
    {{ref('stg_listings')}}