/* ============================================================
   File Name   : 04_product_analytics_queries.sql
   Project     : Healthcare E-commerce Product Analytics
   Purpose     : Funnel, Retention, Cohort & Product Metrics
   Author      : <Your Name>
   Database    : HealthcareProductAnalytics
   ============================================================ */

---------------------------------------------------------------
-- 1. BASIC DATA VALIDATION
---------------------------------------------------------------

SELECT TOP 10 *
FROM orders;

SELECT COUNT(*) AS total_rows
FROM orders;

---------------------------------------------------------------
-- 2. CORE KPI METRICS
---------------------------------------------------------------

SELECT
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(order_id) AS total_orders,
    SUM(order_value) AS total_revenue,
    AVG(order_value) AS avg_order_value
FROM orders;

---------------------------------------------------------------
-- 3. FIRST vs REPEAT ORDER SPLIT
---------------------------------------------------------------

SELECT
    is_repeat_order,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT user_id) AS users
FROM orders
GROUP BY is_repeat_order;

---------------------------------------------------------------
-- 4. OVERALL REPEAT RATE
---------------------------------------------------------------

SELECT
    CAST(SUM(CASE WHEN is_repeat_order = 1 THEN 1 ELSE 0 END) AS FLOAT)
    / COUNT(order_id) AS repeat_rate
FROM orders;

---------------------------------------------------------------
-- 5. FUNNEL: USERS ? ORDERS ? REPEAT ORDERS
---------------------------------------------------------------

SELECT
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN is_repeat_order = 1 THEN order_id END) AS repeat_orders
FROM orders;

---------------------------------------------------------------
-- 6. REPEAT RATE BY PRODUCT CATEGORY
---------------------------------------------------------------

SELECT
    product_category,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN is_repeat_order = 1 THEN 1 ELSE 0 END) AS repeat_orders,
    CAST(SUM(CASE WHEN is_repeat_order = 1 THEN 1 ELSE 0 END) AS FLOAT)
    / COUNT(order_id) AS repeat_rate
FROM orders
GROUP BY product_category
ORDER BY repeat_rate DESC;

---------------------------------------------------------------
-- 7. AVERAGE DAYS BETWEEN ORDERS (RETENTION SIGNAL)
---------------------------------------------------------------

SELECT
    product_category,
    AVG(days_since_last_order) AS avg_days_between_orders
FROM orders
WHERE is_repeat_order = 1
GROUP BY product_category
ORDER BY avg_days_between_orders;

---------------------------------------------------------------
-- 8. POWER USERS (HIGH-VALUE CUSTOMERS)
---------------------------------------------------------------

SELECT
    user_id,
    COUNT(order_id) AS total_orders,
    SUM(order_value) AS lifetime_value
FROM orders
GROUP BY user_id
HAVING COUNT(order_id) >= 5
ORDER BY lifetime_value DESC;

---------------------------------------------------------------
-- 9. COHORT BASE (USER FIRST ORDER DATE)
---------------------------------------------------------------

IF OBJECT_ID('cohort_base', 'U') IS NOT NULL
    DROP TABLE cohort_base;

SELECT
    user_id,
    MIN(order_date) AS first_order_date
INTO cohort_base
FROM orders
GROUP BY user_id;

---------------------------------------------------------------
-- 10. COHORT ORDERS (USER LIFECYCLE TABLE)
---------------------------------------------------------------

IF OBJECT_ID('cohort_orders', 'U') IS NOT NULL
    DROP TABLE cohort_orders;

SELECT
    o.user_id,
    o.order_id,
    o.order_date,
    c.first_order_date,
    DATEDIFF(DAY, c.first_order_date, o.order_date) AS days_since_first_order
INTO cohort_orders
FROM orders o
JOIN cohort_base c
ON o.user_id = c.user_id;

---------------------------------------------------------------
-- 11. CLEAN VIEW FOR DOWNSTREAM ANALYSIS
---------------------------------------------------------------

IF OBJECT_ID('vw_orders_clean', 'V') IS NOT NULL
    DROP VIEW vw_orders_clean;

CREATE VIEW vw_orders_clean AS
SELECT
    order_id,
    user_id,
    order_date,
    days_since_last_order,
    product_category,
    order_value,
    is_repeat_order
FROM orders;

---------------------------------------------------------------
-- END OF FILE
---------------------------------------------------------------
