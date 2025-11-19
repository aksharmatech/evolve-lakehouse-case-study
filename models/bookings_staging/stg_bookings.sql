{{ config(materialized='table') }}

/*
 * Staging model for bookings data
 *
 * Purpose: Cleans and standardizes raw booking data by trimming whitespace and casting to appropriate data types
 *
 * Source: raw.bookings
 * Grain: One row per booking
 *
 * Key transformations:
 * - Trims whitespace from all string fields
 * - Casts IDs and cancelled flag to integer
 * - Casts dates to date type
 * - Standardizes booking type as string
 */

select
    trim(booking_id)::int as booking_id,            -- Unique identifier for the booking
    trim(listing_id)::int as listing_id,            -- Foreign key to listing
    trim(created_date)::date as created_date,       -- Date when booking was created
    trim(checkin_date)::date as checkin_date,       -- Start date of the booking
    trim(checkout_date)::date as checkout_date,     -- End date of the booking
    trim(cancelled)::int as cancelled,              -- Flag indicating if booking was cancelled (0=active, 1=cancelled)
    trim(type)::string as type                      -- Type of booking (e.g., 'guest', 'owner')
from
    {{source('raw','bookings')}}