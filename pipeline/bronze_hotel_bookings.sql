CREATE OR REFRESH STREAMING TABLE
hospitality_catalog.bookings.bronze_hotel_bookings
AS
SELECT
    *,
    _metadata.file_path AS source_file,
    current_timestamp() AS loaded_at
FROM STREAM read_files(
    '/Volumes/hospitality_catalog/bookings/raw_files',
    format => 'csv',
    header => true
);
