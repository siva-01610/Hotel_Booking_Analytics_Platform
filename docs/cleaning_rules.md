# Data Cleaning Rules

1. Remove duplicate bookings using booking_id.
2. Trim extra spaces and standardize text capitalization.
3. Replace blank city and booking channel with Unknown.
4. Calculate missing nights using DATEDIFF.
5. Calculate missing total_amount using nights * room_rate.
6. Keep missing guest_id and guest_rating as NULL.
7. Reject bookings where check_out_date <= check_in_date.
8. Reject bookings with negative room_rate.
9. Keep cancelled bookings in Silver but exclude them from Gold revenue and room nights.
