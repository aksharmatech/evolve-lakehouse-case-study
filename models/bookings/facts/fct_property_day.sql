{{ config(materialized='table') }}

/*
 * Property Day Fact Table
 *
 * Purpose: Provides daily-level metrics for each property listing, including occupancy status and revenue
 *
 * Sources:
 * - stg_bookings (active bookings data)
 * - dim_listing_scd2 (listing dimension with historical tracking)
 * - dim_calendar_date (date dimension)
 *
 * Grain: One row per listing per day (from listing activation to current date)
 *
 * Key metrics:
 * - Occupancy status (guest occupied, owner blocked, or available)
 * - Daily revenue (price if occupied, 0 otherwise)
 * - Listing active status
 *
 * Business logic:
 * - Only considers non-cancelled bookings
 * - Distinguishes between guest bookings (revenue-generating) and owner blocks (non-revenue)
 * - A day cannot be both guest-occupied and owner-blocked (guest bookings take precedence in joins)
 */

with
    -- Filter to only active (non-cancelled) bookings
    c_active_bookings as (
        select
            listing_id,
            checkin_date,
            checkout_date,
            cancelled,
            type
        from
            {{ref('stg_bookings')}}
        where
            cancelled = 0
    ),
    -- Expand owner bookings to create one row per blocked date
    c_owner_booking_blocks as (
        select
            a.listing_id,
            c.date_key
        from
            c_active_bookings a
        left join
            {{ref('dim_calendar_date')}} c
            on
                c.calendar_date between a.checkin_date and a.checkout_date
        where
            a.type = 'owner'
    ),
    -- Expand guest bookings to create one row per occupied date
    c_guest_booking_blocks as (
        select
            a.listing_id,
            c.date_key
        from
            c_active_bookings a
        left join
            {{ref('dim_calendar_date')}} c
            on
                c.calendar_date between a.checkin_date and a.checkout_date
        where
            a.type = 'guest'
    ),
    -- Create base grain of listing x date for all valid listing periods
    c_listing_on_dates as (
        select
            l.listing_id,
            l.is_active,
            l.listing_price,
            c.calendar_date,
            c.date_key
        from
            {{ref('dim_listing_scd2')}} l
        full outer join
            {{ref('dim_calendar_date')}} c
        where
            c.date_key between l.effective_date_from and l.effective_date_to
    )
    select
        l.listing_id,                                                           -- Foreign key to listing dimension
        l.is_active,                                                            -- Flag indicating if listing is currently active
        l.date_key,                                                             -- Foreign key to calendar dimension
        g.date_key is not null as is_occupied,                                  -- Flag: True if booked by a guest
        o.date_key is not null as owner_blocked,                                -- Flag: True if blocked by owner
        g.date_key is null and o.date_key is null as is_available,             -- Flag: True if available for booking
        case when is_occupied then l.listing_price else 0 end as revenue_per_day -- Daily revenue (price if occupied, 0 otherwise)
    from
        c_listing_on_dates l
    left join
        c_owner_booking_blocks o
        on
            l.listing_id = o.listing_id and
            l.date_key = o.date_key
    left join
        c_guest_booking_blocks g
        on
            l.listing_id = g.listing_id and
            l.date_key = g.date_key