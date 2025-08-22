-- sql/etl_pipeline.sql
-- Build an analytics-friendly transaction table

WITH base_transactions AS (
    SELECT 
        user_id,
        CAST(event_date AS DATE) AS transaction_date,
        converted,
        variant
    FROM raw_transactions
),

first_touch AS (
    SELECT 
        user_id,
        MIN(transaction_date) AS signup_date
    FROM base_transactions
    GROUP BY user_id
),

enriched AS (
    SELECT 
        bt.user_id,
        bt.transaction_date,
        bt.converted,
        bt.variant,
        ft.signup_date,
        DATE_TRUNC('month', ft.signup_date) AS signup_month,
        DATE_TRUNC('month', bt.transaction_date) AS event_month
    FROM base_transactions bt
    JOIN first_touch ft ON bt.user_id = ft.user_id
)

SELECT * FROM enriched;