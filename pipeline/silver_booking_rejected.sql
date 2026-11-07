
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.silver_bookings_rejected
AS

WITH ranked_bookings AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY booking_id
            ORDER BY
                booking_date DESC,
                check_in_date DESC,
                check_out_date DESC,
                room_rate DESC,
                total_amount DESC
        ) AS rn
    FROM hospitality_catalog.bookings.bronze_hotel_bookings
),

deduplicated AS (
    SELECT *
    FROM ranked_bookings
    WHERE rn = 1
)

SELECT
    booking_id,
    guest_id,
    booking_date,
    check_in_date,
    check_out_date,
    nights,
    hotel_name,
    city,
    region,
    room_type,
    booking_channel,
    guests,
    room_rate,
    total_amount,
    discount_amount,
    meal_plan,
    payment_method,
    payment_status,
    booking_status,
    guest_rating,
    _rescued_data,
    source_file,
    loaded_at,

    CASE
        WHEN check_in_date IS NULL
          OR check_out_date IS NULL
          OR check_out_date <= check_in_date
            THEN 'Invalid stay dates'

        WHEN room_rate < 0
            THEN 'Negative room rate'
    END AS rejection_reason

FROM deduplicated

WHERE
    check_in_date IS NULL
    OR check_out_date IS NULL
    OR check_out_date <= check_in_date
    OR room_rate < 0;
