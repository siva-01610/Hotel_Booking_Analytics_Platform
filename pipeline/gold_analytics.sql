
-- 1. Monthly Booking Summary
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.gold_monthly_bookings
AS
SELECT
    DATE_FORMAT(booking_date, 'yyyy-MM') AS booking_month,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN 1 ELSE 0 END) AS completed_bookings,
    SUM(CASE WHEN booking_status = 'Cancelled'
        THEN 1 ELSE 0 END) AS cancelled_bookings,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN nights ELSE 0 END) AS completed_room_nights,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN total_amount - discount_amount ELSE 0 END) AS net_revenue
FROM hospitality_catalog.bookings.silver_bookings_clean
GROUP BY DATE_FORMAT(booking_date, 'yyyy-MM');


-- 2. Hotel Performance Summary
-- 2. Hotel Performance Summary
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.gold_hotel_summary
AS
SELECT
    hotel_name,
    COALESCE(
        NULLIF(NULLIF(TRIM(city), ''), 'Unknown'),
        CASE hotel_name
            WHEN 'Backwater Bay Hotel' THEN 'Kochi'
            WHEN 'Desert Rose Inn' THEN 'Jaipur'
            WHEN 'Garden City Hotel' THEN 'Bengaluru'
            WHEN 'Lake View Retreat' THEN 'Udaipur'
            WHEN 'Marine Drive Suites' THEN 'Mumbai'
            WHEN 'Palm Grove Hotel' THEN 'Goa'
            WHEN 'Pink City Palace' THEN 'Jaipur'
            WHEN 'Sea Breeze Resort' THEN 'Goa'
            WHEN 'Pine Hills Lodge' THEN 'Shimla'
            WHEN 'Spice Coast Residency' THEN 'Kochi'
        END
    ) AS city,
    region,
    COUNT(*) AS total_bookings,
    SUM(
        CASE WHEN booking_status = 'Completed'
        THEN COALESCE(total_amount, 0) - COALESCE(discount_amount, 0)
        ELSE 0 END
    ) AS net_revenue,
    SUM(
        CASE WHEN booking_status = 'Completed'
        THEN nights ELSE 0 END
    ) AS room_nights,
    ROUND(
        SUM(
            CASE WHEN booking_status = 'Completed'
            THEN COALESCE(total_amount, 0) - COALESCE(discount_amount, 0)
            ELSE 0 END
        ) /
        NULLIF(
            SUM(CASE WHEN booking_status = 'Completed'
            THEN nights ELSE 0 END), 0
        ), 2
    ) AS adr
FROM hospitality_catalog.bookings.silver_bookings_clean
GROUP BY
    hotel_name,
    COALESCE(
        NULLIF(NULLIF(TRIM(city), ''), 'Unknown'),
        CASE hotel_name
            WHEN 'Backwater Bay Hotel' THEN 'Kochi'
            WHEN 'Desert Rose Inn' THEN 'Jaipur'
            WHEN 'Garden City Hotel' THEN 'Bengaluru'
            WHEN 'Lake View Retreat' THEN 'Udaipur'
            WHEN 'Marine Drive Suites' THEN 'Mumbai'
            WHEN 'Palm Grove Hotel' THEN 'Goa'
            WHEN 'Pink City Palace' THEN 'Jaipur'
            WHEN 'Sea Breeze Resort' THEN 'Goa'
            WHEN 'Pine Hills Lodge' THEN 'Shimla'
            WHEN 'Spice Coast Residency' THEN 'Kochi'
        END
    ),
    region;


-- 3. Room Type Summary
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.gold_room_type_summary
AS
SELECT
    room_type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN nights ELSE 0 END) AS completed_room_nights,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN total_amount - discount_amount ELSE 0 END) AS net_revenue,
    ROUND(AVG(guest_rating), 2) AS avg_guest_rating
FROM hospitality_catalog.bookings.silver_bookings_clean
GROUP BY room_type;


-- 4. Booking Channel Summary
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.gold_channel_summary
AS
SELECT
    booking_channel,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Cancelled'
        THEN 1 ELSE 0 END) AS cancelled_bookings,
    ROUND(
        100.0 * SUM(CASE WHEN booking_status = 'Cancelled'
            THEN 1 ELSE 0 END) / COUNT(*)
    , 2) AS cancellation_rate_pct,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN total_amount - discount_amount ELSE 0 END) AS net_revenue
FROM hospitality_catalog.bookings.silver_bookings_clean
GROUP BY booking_channel;


-- 5. Data Quality Summary
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.gold_data_quality
AS
SELECT
    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings)
        AS bronze_rows,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_clean)
    +
    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_rejected)
        AS deduplicated_rows,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_clean)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_rejected)
        AS rejected_rows,

    (SELECT COUNT(*) - COUNT(DISTINCT booking_id)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings)
        AS duplicate_rows,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE check_in_date IS NULL
        OR check_out_date IS NULL
        OR check_out_date <= check_in_date)
        AS invalid_date_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE room_rate < 0)
        AS negative_room_rate_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE city IS NULL OR TRIM(city) = '')
        AS missing_city_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE booking_channel IS NULL OR TRIM(booking_channel) = '')
        AS missing_booking_channel_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE guest_id IS NULL OR TRIM(guest_id) = '')
        AS missing_guest_id_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE nights IS NULL OR TRIM(CAST(nights AS STRING)) = '')
        AS missing_nights_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings
     WHERE total_amount IS NULL OR TRIM(CAST(total_amount AS STRING)) = '')
        AS missing_total_amount_count,

    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings)
    -
    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_clean)
    -
    (SELECT COUNT(*)
     FROM hospitality_catalog.bookings.silver_bookings_rejected)
    -
    (SELECT COUNT(*) - COUNT(DISTINCT booking_id)
     FROM hospitality_catalog.bookings.bronze_hotel_bookings)
        AS reconciliation_gap,

    CASE
        WHEN (
            (SELECT COUNT(*)
             FROM hospitality_catalog.bookings.bronze_hotel_bookings)
            -
            (SELECT COUNT(*)
             FROM hospitality_catalog.bookings.silver_bookings_clean)
            -
            (SELECT COUNT(*)
             FROM hospitality_catalog.bookings.silver_bookings_rejected)
            -
            (SELECT COUNT(*) - COUNT(DISTINCT booking_id)
             FROM hospitality_catalog.bookings.bronze_hotel_bookings)
        ) = 0
        THEN 'Passed'
        ELSE 'Failed'
    END AS reconciliation_status;
