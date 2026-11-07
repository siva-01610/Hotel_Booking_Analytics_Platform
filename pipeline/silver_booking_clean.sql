
CREATE OR REFRESH MATERIALIZED VIEW
hospitality_catalog.bookings.silver_bookings_clean (
    CONSTRAINT valid_stay_dates EXPECT (
        check_in_date IS NOT NULL
        AND check_out_date IS NOT NULL
        AND check_out_date > check_in_date
    ) ON VIOLATION DROP ROW,
    CONSTRAINT non_negative_room_rate EXPECT (room_rate >= 0) ON VIOLATION DROP ROW
)
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
    TRIM(booking_id) AS booking_id,
    NULLIF(TRIM(guest_id), '') AS guest_id,
    booking_date,
    check_in_date,
    check_out_date,
    DATEDIFF(check_out_date, check_in_date) AS nights,
    INITCAP(TRIM(hotel_name)) AS hotel_name,
    CASE WHEN city IS NULL OR TRIM(city) = '' THEN 'Unknown' ELSE INITCAP(TRIM(city)) END AS city,
    INITCAP(TRIM(region)) AS region,
    INITCAP(TRIM(room_type)) AS room_type,
    CASE WHEN booking_channel IS NULL OR TRIM(booking_channel) = '' THEN 'Unknown' ELSE INITCAP(TRIM(booking_channel)) END AS booking_channel,
    guests,
    room_rate,
    COALESCE(total_amount, DATEDIFF(check_out_date, check_in_date) * room_rate) AS total_amount,
    discount_amount,
    INITCAP(TRIM(meal_plan)) AS meal_plan,
    INITCAP(TRIM(payment_method)) AS payment_method,
    INITCAP(TRIM(payment_status)) AS payment_status,
    INITCAP(TRIM(booking_status)) AS booking_status,
    guest_rating,
    source_file,
    loaded_at

FROM deduplicated;
