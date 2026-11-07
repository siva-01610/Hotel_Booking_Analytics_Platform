# Hotel Booking Analytics Platform

An end-to-end beginner Data Engineering internship project built with
**Databricks**, **Lakeflow Spark Declarative Pipelines**, **Unity
Catalog**, SQL, and the **Medallion Architecture**.

## Project Overview

A hotel group exports booking records to a CSV file. The source data
contains common data-quality issues such as duplicate bookings,
inconsistent text formatting, blank values, impossible stay dates, and
negative room rates.

This project ingests the raw CSV into Databricks, preserves it in the
Bronze layer, cleans and separates records in the Silver layer, and
creates business-ready Gold summary tables for reporting. A three-page
Databricks AI/BI dashboard presents the results.

The dataset is synthetic and contains no real guest data.

## Project Objectives

-   Load the hotel bookings CSV from a Unity Catalog Volume.
-   Preserve source records in a Bronze streaming table.
-   Clean valid records and retain rejected records separately in
    Silver.
-   Create Gold summaries for monthly trends, hotels, room types,
    booking channels, and data quality.
-   Reconcile the source records against clean, rejected, and duplicate
    records.
-   Build and publish one dashboard with three pages.

## Technology Stack

-   Databricks
-   Lakeflow Spark Declarative Pipelines
-   Unity Catalog Volumes
-   Databricks SQL
-   Medallion Architecture (Bronze, Silver, Gold)
-   Databricks AI/BI Dashboards
-   GitHub

## Architecture

``` text
Synthetic CSV
    |
    v
Unity Catalog Volume
    |
    v
Bronze: bronze_hotel_bookings
    |
    v
Silver
    |-- Clean bookings: silver_clean
    |-- Rejected bookings: silver_bookings_rejected
    |
    v
Gold
    |-- gold_monthly_bookings
    |-- gold_hotel_summary
    |-- gold_room_type_summary
    |-- gold_channel_summary
    |-- gold_data_quality
    |
    v
Databricks AI/BI Dashboard
    |-- Executive Overview
    |-- Hotel, Room & Channel Analysis
    |-- Data Quality
```

## Databricks Objects

  Object                   Name
  ------------------------ ----------------------------
  Catalog                  `hospitality_catalog`
  Schema                   `bookings`
  Volume                   `raw_files`
  Bronze table             `bronze_hotel_bookings`
  Silver clean table       `silver_clean`
  Silver rejected table    `silver_bookings_rejected`
  Gold monthly summary     `gold_monthly_bookings`
  Gold hotel summary       `gold_hotel_summary`
  Gold room type summary   `gold_room_type_summary`
  Gold channel summary     `gold_channel_summary`
  Gold data quality        `gold_data_quality`
  Pipeline                 `Hotel_Booking_ETL`

> The Silver clean table is documented as `silver_clean`, matching the
> table name verified in the Databricks workspace.

## Dataset

-   Source file: `hotel_bookings_raw.csv`
-   Dataset type: Synthetic hotel booking data
-   Source rows: 1,316
-   Source columns: 20
-   Booking period: 2025

One row represents one booking. `booking_id` is used to identify
duplicate booking records.

## Data Cleaning Rules

The Silver layer applies the following rules:

1.  **Deduplication:** Remove extra records with the same `booking_id`.
2.  **Text standardization:** Trim extra spaces and standardize text
    capitalization.
3.  **Missing city and channel:** Replace blank values with `Unknown`.
4.  **Missing nights:** Calculate nights using the difference between
    check-out and check-in dates.
5.  **Missing total amount:** Calculate using nights multiplied by room
    rate.
6.  **Guest ID and guest rating:** Preserve missing values as `NULL`.
7.  **Invalid stay dates:** Reject records where check-out is on or
    before check-in.
8.  **Negative room rate:** Reject records with a negative room rate.
9.  **Cancelled bookings:** Keep cancelled bookings in Silver. Exclude
    them from Gold revenue and completed room-night calculations.

## Business Formulas

-   `nights = DATEDIFF(check_out_date, check_in_date)`
-   `total_amount = nights × room_rate` when the source amount is
    missing.
-   `net_revenue = total_amount − discount_amount` for completed
    bookings only.
-   `room_nights = SUM(nights)` for completed bookings only.
-   `ADR = net_revenue ÷ room_nights`.

## Verified Results

The following results were checked in the Databricks workspace during
project validation.

  Metric                              Verified result
  --------------------------------- -----------------
  Bronze rows                                   1,316
  Deduplicated rows                             1,290
  Clean Silver rows                             1,269
  Rejected rows                                    21
  Duplicate rows removed                           26
  Gold monthly summary records                     14
  Gold hotel summary records                       10
  Gold room type summary records                    4
  Gold channel summary records                      5
  Gold data quality records                         1
  Completed bookings                            1,083
  Cancelled bookings in Silver                    186
  Completed room nights                         3,107
  Gross completed-booking amount      ₹1,58,49,700.00
  Discounts on completed bookings        ₹7,95,103.50
  Gold net revenue                    ₹1,50,54,596.50

### Reconciliation

``` text
Bronze rows = Clean rows + Rejected rows + Duplicate rows

1,316 = 1,269 + 21 + 26
```

The reconciliation gap is zero.

### Revenue validation

``` text
Net revenue = Gross revenue - Discounts

₹1,58,49,700.00 - ₹7,95,103.50
= ₹1,50,54,596.50
```

The calculated completed-booking net revenue matches the Gold monthly
summary revenue.

## Dashboard

One Databricks AI/BI dashboard was configured with three pages and
published.

### 1. Executive Overview

-   Total bookings
-   Net revenue
-   Room nights
-   Cancelled bookings
-   Monthly revenue trend
-   City-wise revenue

### 2. Hotel, Room & Channel Analysis

-   Net revenue by hotel
-   City-wise hotel performance
-   Room type revenue and guest rating
-   Booking channel performance
-   Hotel performance details
-   Cancellation rate by channel

### 3. Data Quality

-   Bronze, deduplicated, clean, rejected, and duplicate row counts
-   Reconciliation gap and status
-   Row reconciliation by stage
-   Data-quality problem counts

## Pipeline

The Databricks Lakeflow Spark Declarative Pipeline is named
`Hotel_Booking_ETL`.

**Latest validation status:** Pipeline run succeeded. The Databricks
dashboard was also published.

## Repository Structure

``` text
Hotel_Booking_Analytics_Platform/
├── README.md
├── data/
│   └── hotel_bookings_raw.csv
├── pipeline/
│   └── Hotel_Booking_ETL.sql
├── dashboard/
│   └── dashboard_screenshots/
├── screenshots/
│   ├── bronze_table.png
│   ├── silver_clean.png
│   ├── silver_rejected.png
│   ├── gold_tables.png
│   ├── pipeline_graph.png
│   └── reconciliation.png
└── docs/
    └── cleaning_rules.md
```

This is the planned repository structure. Add the corresponding files
and screenshots as they are exported from the Databricks workspace. Do
not upload credentials, tokens, or other secrets.

## How to Run

1.  Open the Databricks workspace.
2.  Confirm that the `hospitality_catalog.bookings` schema and
    `raw_files` Volume exist.
3.  Upload the synthetic `hotel_bookings_raw.csv` file into the Volume.
4.  Open the `Hotel_Booking_ETL` Lakeflow Spark Declarative Pipeline.
5.  Run the pipeline and wait for a successful completion.
6.  Verify the Bronze, Silver, and Gold tables.
7.  Open the published Databricks AI/BI dashboard.

The SQL pipeline source and screenshots should be added to this
repository to make the implementation reproducible.

## Project Scope

This is a beginner learning project based on one synthetic CSV source
and batch ingestion from a Unity Catalog Volume. It does not implement
live room availability, real-time booking ingestion, occupancy
calculations, dynamic pricing, multiple source systems, or advanced
dimensional modelling.

## Acknowledgements

Completed as a Data Engineering internship portfolio project using the
supplied Hotel Booking Analytics Platform project brief.
