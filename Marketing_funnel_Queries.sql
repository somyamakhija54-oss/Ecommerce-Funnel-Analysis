-- Query 1: Executive Funnel Drop-off Analysis

WITH funnel_stages AS (
    SELECT 
        COUNT(session_id) AS total_visits,
        SUM(CASE WHEN viewed_product THEN 1 ELSE 0 END) AS product_views,
        SUM(CASE WHEN added_to_cart THEN 1 ELSE 0 END) AS cart_adds,
        SUM(CASE WHEN checkout_started THEN 1 ELSE 0 END) AS checkouts,
        SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS purchases
    FROM "Marketing_Funnel"
)
SELECT '1. Website Visit' AS funnel_stage, total_visits AS user_count, 100.0 AS stage_conversion_rate FROM funnel_stages
UNION ALL
SELECT '2. Product View', product_views, ROUND(product_views * 100.0 / total_visits, 2) FROM funnel_stages
UNION ALL
SELECT '3. Add to Cart', cart_adds, ROUND(cart_adds * 100.0 / product_views, 2) FROM funnel_stages
UNION ALL
SELECT '4. Checkout Started', checkouts, ROUND(checkouts * 100.0 / cart_adds, 2) FROM funnel_stages
UNION ALL
SELECT '5. Purchase Completed', purchases, ROUND(purchases * 100.0 / checkouts, 2) FROM funnel_stages;

-- Query 2: Acquisition Channel Performance & Revenue Attribution

SELECT 
    channel,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_conversions,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(SUM(revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue_per_session
FROM "Marketing_Funnel"
GROUP BY channel
ORDER BY total_revenue DESC;

--Query 3: Campaign Type Efficiency & ROI Evaluation

SELECT 
    campaign_type,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_conversions,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(SUM(order_value)::numeric, 2) AS total_order_value,
    ROUND(SUM(revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue_per_session
FROM "Marketing_Funnel"
GROUP BY campaign_type
ORDER BY total_revenue DESC;

--Query 4: Discount Impact & Margin Cannibalization Study

SELECT 
    discount_applied,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(AVG(order_value)::numeric, 2) AS average_order_value,
    ROUND(AVG(revenue)::numeric, 2) AS average_revenue_per_session,
    ROUND(SUM(revenue)::numeric, 2) AS total_generated_revenue
FROM "Marketing_Funnel"
GROUP BY discount_applied;

--Query 5: Cart Abandonment Rate by Acquisition Channel

SELECT 
    channel,
    SUM(CASE WHEN added_to_cart THEN 1 ELSE 0 END) AS added_to_cart_count,
    SUM(CASE WHEN added_to_cart AND NOT checkout_started THEN 1 ELSE 0 END) AS cart_abandoned_count,
    ROUND(
        (SUM(CASE WHEN added_to_cart AND NOT checkout_started THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN added_to_cart THEN 1 ELSE 0 END), 0))::numeric, 2
    ) AS cart_abandonment_rate_pct
FROM "Marketing_Funnel"
GROUP BY channel
ORDER BY cart_abandonment_rate_pct DESC;

--Query 6: User Segmentation: New vs. Returning Behavioral Analysis

SELECT 
    user_type,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(AVG(order_value)::numeric, 2) AS avg_order_value,
    ROUND(SUM(revenue)::numeric, 2) AS total_revenue
FROM "Marketing_Funnel"
GROUP BY user_type
ORDER BY total_revenue DESC;

--Query 7: Device Preference & Platform Performance (Mobile vs. Desktop)

SELECT 
    device,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(SUM(revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue_per_session
FROM "Marketing_Funnel"
GROUP BY device
ORDER BY total_revenue DESC;

--Query 8: Regional & Tier-Based Market Performance

SELECT 
    region,
    COUNT(session_id) AS total_sessions,
    SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
    ROUND((SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) * 100.0 / COUNT(session_id))::numeric, 2) AS conversion_rate,
    ROUND(SUM(revenue)::numeric, 2) AS total_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue_per_session
FROM "Marketing_Funnel"
GROUP BY region
ORDER BY total_revenue DESC;

--Query 9: RFM-Style High-Value Customer Tier Segmentation

WITH user_revenue AS (
    SELECT 
        user_id,
        COUNT(session_id) AS total_sessions,
        SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
        SUM(revenue) AS lifetime_revenue
    FROM "Marketing_Funnel"
    GROUP BY user_id
),
segmented_users AS (
    SELECT 
        user_id,
        total_sessions,
        total_purchases,
        lifetime_revenue,
        CASE 
            WHEN lifetime_revenue >= 2000 THEN 'High Value'
            WHEN lifetime_revenue BETWEEN 500 AND 1999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_segment
    FROM user_revenue
)
SELECT 
    value_segment,
    COUNT(user_id) AS user_count,
    ROUND(SUM(lifetime_revenue)::numeric, 2) AS segment_total_revenue,
    ROUND(AVG(lifetime_revenue)::numeric, 2) AS avg_revenue_per_user
FROM segmented_users
GROUP BY value_segment
ORDER BY segment_total_revenue DESC;

--Query 10: Monthly Revenue Trends & Month-over-Month (MoM) Growth

WITH monthly_metrics AS (
    SELECT 
        month,
        COUNT(session_id) AS total_sessions,
        SUM(CASE WHEN purchase_completed THEN 1 ELSE 0 END) AS total_purchases,
        SUM(revenue) AS monthly_revenue
    FROM "Marketing_Funnel"
    GROUP BY month
),
mom_calculation AS (
    SELECT 
        month,
        total_sessions,
        total_purchases,
        ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
        ROUND(LAG(monthly_revenue, 1) OVER (ORDER BY month)::numeric, 2) AS previous_month_revenue
    FROM monthly_metrics
)
SELECT 
    month,
    total_sessions,
    total_purchases,
    monthly_revenue,
    previous_month_revenue,
    CASE 
        WHEN previous_month_revenue IS NULL THEN 0.0
        ELSE ROUND((((monthly_revenue - previous_month_revenue) * 100.0) / previous_month_revenue)::numeric, 2)
    END AS mom_growth_percentage
FROM mom_calculation
ORDER BY month ASC;
