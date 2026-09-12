-- ============================================================
-- SaaS Customer Churn & Retention Intelligence
-- STAGE 4: SQL ANALYSIS
-- Database: MySQL 8.0+
-- Generated from the project's customers.csv and subscription_monthly.csv
--
-- IMPORTANT:
-- 1. subscription_monthly contains only active subscription-month rows.
-- 2. A customer is considered churned when their active monthly history
--    stops; the customer table also contains the churn flag/date.
-- 3. Do not use is_active = 0 to find churn: no such rows exist in
--    the supplied subscription data.
-- 4. The outputs below are the expected results for this dataset.
-- ============================================================


-- ============================================================
-- 0. TABLE SETUP
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    signup_date DATE,
    plan_tier VARCHAR(30),
    monthly_price DECIMAL(10,2),
    contract_type VARCHAR(30),
    payment_method VARCHAR(40),
    country VARCHAR(50),
    industry VARCHAR(80),
    company_size_employees INT,
    monthly_active_users_pct DECIMAL(6,3),
    feature_adoption_count INT,
    support_tickets_90d INT,
    avg_csat_score DECIMAL(4,2),
    failed_payments_90d INT,
    last_login_days_ago INT,
    churned TINYINT,
    churn_date DATE NULL,
    tenure_months INT,
    lifetime_revenue DECIMAL(12,2)
);

CREATE TABLE IF NOT EXISTS subscription_monthly (
    customer_id VARCHAR(20),
    month DATE,
    tenure_month INT,
    is_active TINYINT,
    mrr DECIMAL(10,2),
    PRIMARY KEY (customer_id, month)
);


-- ============================================================
-- 1. DATASET / OBSERVATION-WINDOW CHECKS
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id) AS customers
FROM customers;

-- Expected:
-- 6000


SELECT
    MIN(month) AS observation_start,
    MAX(month) AS observation_end,
    COUNT(DISTINCT customer_id) AS customers
FROM subscription_monthly;

-- Expected:
-- observation_start = 2023-01-01
-- observation_end   = 2026-08-01
-- customers         = 6000


-- ============================================================
-- 2. FIND EACH CUSTOMER'S LAST ACTIVE MONTH
-- ============================================================

SELECT
    customer_id,
    MAX(month) AS last_active_month
FROM subscription_monthly
GROUP BY customer_id
ORDER BY customer_id;

-- Purpose:
-- Creates the final observed active month for every customer.
-- This is useful for churn/survival analysis because active customers
-- at the observation end are right-censored rather than automatically
-- treated as churned.


-- ============================================================
-- 3. MONTHLY CHURN
-- ============================================================
-- Monthly churn is defined here as:
-- churned customers in month
-- --------------------------------
-- customers active in the previous month
--
-- The denominator uses the previous month's active population.

WITH monthly_churn AS (
    SELECT
        DATE_FORMAT(churn_date, '%Y-%m-01') AS churn_month,
        COUNT(*) AS churned_customers,
        SUM(monthly_price) AS mrr_lost
    FROM customers
    WHERE churned = 1
    GROUP BY DATE_FORMAT(churn_date, '%Y-%m-01')
),
monthly_active AS (
    SELECT
        DATE_FORMAT(month, '%Y-%m-01') AS active_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM subscription_monthly
    GROUP BY DATE_FORMAT(month, '%Y-%m-01')
)
SELECT
    mc.churn_month,
    mc.churned_customers,
    ma.active_customers AS active_customers_previous_month,
    ROUND(
        mc.churned_customers / NULLIF(ma.active_customers, 0) * 100,
        2
    ) AS monthly_churn_rate_pct,
    mc.mrr_lost
FROM monthly_churn mc
LEFT JOIN monthly_active ma
    ON ma.active_month = DATE_FORMAT(
        DATE_SUB(STR_TO_DATE(mc.churn_month, '%Y-%m-%d'), INTERVAL 1 MONTH),
        '%Y-%m-01'
    )
ORDER BY mc.churn_month;

-- Expected output:
-- churn_month | churned | active_start | churn_rate_% | mrr_lost
2023-02 | 4 | 139 | 2.877698 | 166
2023-03 | 4 | 287 | 1.393728 | 436
2023-04 | 3 | 424 | 0.707547 | 477
2023-05 | 15 | 550 | 2.727273 | 1005
2023-06 | 17 | 679 | 2.503682 | 1643
2023-07 | 11 | 798 | 1.378446 | 1149
2023-08 | 12 | 903 | 1.328904 | 1228
2023-09 | 14 | 1029 | 1.360544 | 1266
2023-10 | 19 | 1167 | 1.628106 | 1361
2023-11 | 11 | 1292 | 0.851393 | 1199
2023-12 | 23 | 1417 | 1.623147 | 1777
2024-01 | 35 | 1535 | 2.280130 | 3145
2024-02 | 26 | 1644 | 1.581509 | 2154
2024-03 | 29 | 1741 | 1.665709 | 2051
2024-04 | 26 | 1855 | 1.401617 | 1834
2024-05 | 34 | 2002 | 1.698302 | 2626
2024-06 | 34 | 2099 | 1.619819 | 3526
2024-07 | 38 | 2203 | 1.724921 | 2212
2024-08 | 27 | 2325 | 1.161290 | 1963
2024-09 | 30 | 2426 | 1.236603 | 2850
2024-10 | 28 | 2524 | 1.109350 | 2012
2024-11 | 33 | 2622 | 1.258581 | 2527
2024-12 | 28 | 2754 | 1.016703 | 2012
2025-01 | 34 | 2869 | 1.185082 | 2916
2025-02 | 43 | 2983 | 1.441502 | 2877
2025-03 | 47 | 3069 | 1.531443 | 3443
2025-04 | 31 | 3168 | 0.978535 | 2879
2025-05 | 24 | 3265 | 0.735069 | 1656
2025-06 | 37 | 3380 | 1.094675 | 2743
2025-07 | 34 | 3497 | 0.972262 | 2516
2025-08 | 36 | 3622 | 0.993926 | 2954
2025-09 | 27 | 3720 | 0.725806 | 1693
2025-10 | 37 | 3812 | 0.970619 | 3253
2025-11 | 49 | 3916 | 1.251277 | 4411
2025-12 | 44 | 4013 | 1.096437 | 4066
2026-01 | 44 | 4106 | 1.071603 | 3566
2026-02 | 43 | 4188 | 1.026743 | 3527
2026-03 | 51 | 4290 | 1.188811 | 4299
2026-04 | 47 | 4372 | 1.075023 | 3743
2026-05 | 39 | 4481 | 0.870341 | 3631
2026-06 | 48 | 4571 | 1.050098 | 3532
2026-07 | 44 | 4684 | 0.939368 | 4666
2026-08 | 48 | 4784 | 1.003344 | 4262
-- ============================================================


-- ============================================================
-- 4. TOP CONTRACT SEGMENTS
-- ============================================================

SELECT
    contract_type,
    COUNT(*) AS customers,
    SUM(churned) AS churned_customers,
    SUM(monthly_price) AS total_mrr,
    SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END) AS mrr_lost,
    ROUND(SUM(churned) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(
        SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END)
        / SUM(monthly_price) * 100,
        2
    ) AS revenue_churn_rate_pct
FROM customers
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;

-- Expected output:
-- contract_type | customers | churned | total_mrr | mrr_lost | churn_rate | revenue_churn
Month-to-month | 3257 | 850 | 263493 | 67860 | 26.097636 | 25.754005
1-Year | 1822 | 323 | 149248 | 27687 | 17.727772 | 18.551002
2-Year | 921 | 135 | 74859 | 11705 | 14.657980 | 15.636062
-- ============================================================


-- ============================================================
-- 5. PLAN-LEVEL CHURN AND REVENUE IMPACT
-- ============================================================

SELECT
    plan_tier,
    COUNT(*) AS customers,
    SUM(churned) AS churned_customers,
    SUM(monthly_price) AS total_mrr,
    SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END) AS mrr_lost,
    ROUND(SUM(churned) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(
        SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END)
        / SUM(monthly_price) * 100,
        2
    ) AS revenue_churn_rate_pct
FROM customers
GROUP BY plan_tier
ORDER BY churn_rate_pct DESC;

-- Expected output:
-- plan_tier | customers | churned | total_mrr | mrr_lost | churn_rate | revenue_churn
Enterprise | 1210 | 271 | 240790 | 53929 | 22.396694 | 22.396694
Basic | 2632 | 572 | 76328 | 16588 | 21.732523 | 21.732523
Pro | 2158 | 465 | 170482 | 36735 | 21.547729 | 21.547729
-- ============================================================


-- ============================================================
-- 6. COUNTRY-LEVEL CHURN
-- ============================================================

SELECT
    country,
    COUNT(*) AS customers,
    SUM(churned) AS churned_customers,
    ROUND(SUM(churned) / COUNT(*) * 100, 2) AS churn_rate_pct,
    SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END) AS mrr_lost
FROM customers
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- Expected output:
-- country | customers | churned | churn_rate | mrr_lost
Australia | 600 | 134 | 22.333333 | 10956
UK | 908 | 201 | 22.136564 | 16329
India | 1207 | 264 | 21.872411 | 22386
Germany | 758 | 165 | 21.767810 | 12745
USA | 1841 | 400 | 21.727322 | 32020
Canada | 686 | 144 | 20.991254 | 12816
-- ============================================================


-- ============================================================
-- 7. PAYMENT-METHOD CHURN
-- ============================================================

SELECT
    payment_method,
    COUNT(*) AS customers,
    SUM(churned) AS churned_customers,
    ROUND(SUM(churned) / COUNT(*) * 100, 2) AS churn_rate_pct,
    SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END) AS mrr_lost
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- Expected output:
-- payment_method | customers | churned | churn_rate | mrr_lost
ACH/Bank Transfer | 1192 | 272 | 22.818792 | 22858
Credit Card | 3292 | 739 | 22.448360 | 61631
PayPal | 912 | 191 | 20.942982 | 14659
Manual Invoice | 604 | 106 | 17.549669 | 8104
-- ============================================================


-- ============================================================
-- 8. REVENUE LOST BY CHURN MONTH
-- ============================================================

SELECT
    DATE_FORMAT(churn_date, '%Y-%m') AS churn_month,
    COUNT(*) AS churned_customers,
    SUM(monthly_price) AS mrr_lost
FROM customers
WHERE churned = 1
GROUP BY DATE_FORMAT(churn_date, '%Y-%m')
ORDER BY churn_month;

-- Total expected:
-- churned_customers = 1308
-- mrr_lost = 107252


-- ============================================================
-- 9. COHORT RETENTION
-- ============================================================
-- Cohort = customer's signup month.
-- Retention at month N = customers with an active subscription in
-- cohort month + N / original cohort size.

WITH customer_cohorts AS (
    SELECT
        customer_id,
        DATE_FORMAT(signup_date, '%Y-%m-01') AS cohort_month
    FROM customers
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
monthly_activity AS (
    SELECT DISTINCT
        s.customer_id,
        cc.cohort_month,
        DATE_FORMAT(s.month, '%Y-%m-01') AS activity_month
    FROM subscription_monthly s
    JOIN customer_cohorts cc
        ON s.customer_id = cc.customer_id
),
cohort_activity AS (
    SELECT
        cohort_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(cohort_month, '%Y-%m-%d'),
            STR_TO_DATE(activity_month, '%Y-%m-%d')
        ) AS months_since_signup,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM monthly_activity
    GROUP BY cohort_month, months_since_signup
)
SELECT
    ca.cohort_month,
    ca.months_since_signup,
    cs.cohort_size,
    ca.active_customers,
    ROUND(ca.active_customers / cs.cohort_size * 100, 2)
        AS retention_rate_pct
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_month = cs.cohort_month
WHERE ca.months_since_signup BETWEEN 0 AND 12
ORDER BY ca.cohort_month, ca.months_since_signup;

-- Expected first cohort:
-- cohort 2023-01:
-- Month 0  = 100.00%
-- Month 1  = 100.00%
-- Month 2  = 99.28%
-- Month 3  = 98.56%
-- Month 4  = 97.84%
-- Month 5  = 95.68%
-- Month 6  = 92.81%
-- Month 7  = 91.37%
-- Month 8  = 90.65%
-- Month 9  = 90.65%
-- Month 10 = 89.21%
-- Month 11 = 87.77%
-- Month 12 = 87.77%


-- ============================================================
-- 10. CUSTOMER RISK-SIGNAL VIEW
-- ============================================================
-- IMPORTANT:
-- This is NOT the final ML risk score.
-- It is only a SQL screening view showing customers with multiple
-- observed warning signals.
--
-- Signals:
-- 1 = month-to-month contract
-- 1 = low usage (<33%)
-- 1 = low CSAT (<3)
-- 1 = at least one failed payment
-- 1 = inactive for >30 days
--
-- Maximum signal count = 5.

WITH last_active AS (
    SELECT
        customer_id,
        MAX(month) AS last_active_month
    FROM subscription_monthly
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.plan_tier,
    c.contract_type,
    c.monthly_price,
    c.monthly_active_users_pct,
    c.avg_csat_score,
    c.failed_payments_90d,
    c.last_login_days_ago,
    (
        (CASE WHEN c.contract_type = 'Month-to-month' THEN 1 ELSE 0 END) +
        (CASE WHEN c.monthly_active_users_pct < 0.33 THEN 1 ELSE 0 END) +
        (CASE WHEN c.avg_csat_score < 3 THEN 1 ELSE 0 END) +
        (CASE WHEN c.failed_payments_90d > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN c.last_login_days_ago > 30 THEN 1 ELSE 0 END)
    ) AS risk_signal_count,
    CASE
        WHEN (
            (CASE WHEN c.contract_type = 'Month-to-month' THEN 1 ELSE 0 END) +
            (CASE WHEN c.monthly_active_users_pct < 0.33 THEN 1 ELSE 0 END) +
            (CASE WHEN c.avg_csat_score < 3 THEN 1 ELSE 0 END) +
            (CASE WHEN c.failed_payments_90d > 0 THEN 1 ELSE 0 END) +
            (CASE WHEN c.last_login_days_ago > 30 THEN 1 ELSE 0 END)
        ) >= 4 THEN 'High'
        WHEN (
            (CASE WHEN c.contract_type = 'Month-to-month' THEN 1 ELSE 0 END) +
            (CASE WHEN c.monthly_active_users_pct < 0.33 THEN 1 ELSE 0 END) +
            (CASE WHEN c.avg_csat_score < 3 THEN 1 ELSE 0 END) +
            (CASE WHEN c.failed_payments_90d > 0 THEN 1 ELSE 0 END) +
            (CASE WHEN c.last_login_days_ago > 30 THEN 1 ELSE 0 END)
        ) >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS risk_band
FROM customers c
JOIN last_active la
    ON c.customer_id = la.customer_id
WHERE c.churned = 0
ORDER BY risk_signal_count DESC, c.monthly_price DESC
LIMIT 10;

-- Expected top 10 sample:
-- customer_id | plan | contract | price | usage | csat | failed | login | signals | band
C01051 | Pro | Month-to-month | 79 | 0.304000 | 2.600000 | 0 | 34 | 4 | High
C01071 | Pro | Month-to-month | 79 | 0.256000 | 2.520000 | 1 | 5 | 4 | High
C01208 | Pro | Month-to-month | 79 | 0.328000 | 2.300000 | 1 | 3 | 4 | High
C01838 | Pro | Month-to-month | 79 | 0.241000 | 2.040000 | 1 | 0 | 4 | High
C03795 | Pro | Month-to-month | 79 | 0.878000 | 2.600000 | 2 | 37 | 4 | High
C04041 | Pro | Month-to-month | 79 | 0.257000 | 2.690000 | 1 | 2 | 4 | High
C00079 | Basic | Month-to-month | 29 | 0.203000 | 1.770000 | 1 | 6 | 4 | High
C00998 | Basic | Month-to-month | 29 | 0.309000 | 5.000000 | 1 | 37 | 4 | High
C02488 | Basic | Month-to-month | 29 | 0.286000 | 3.830000 | 1 | 44 | 4 | High
C04857 | Basic | Month-to-month | 29 | 0.309000 | 4.850000 | 1 | 47 | 4 | High
-- ============================================================


-- ============================================================
-- 11. OVERALL KPI CROSS-CHECK
-- ============================================================

SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(churned) AS churned_customers,
    ROUND(SUM(churned) / COUNT(*) * 100, 2) AS customer_churn_rate_pct,
    ROUND(100 - SUM(churned) / COUNT(*) * 100, 2) AS retention_rate_pct,
    SUM(monthly_price) AS total_mrr,
    SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END) AS mrr_lost,
    ROUND(
        SUM(CASE WHEN churned = 1 THEN monthly_price ELSE 0 END)
        / SUM(monthly_price) * 100,
        2
    ) AS revenue_churn_rate_pct,
    ROUND(AVG(monthly_price), 2) AS arpu
FROM customers;

-- Expected:
-- total_customers       = 6000
-- churned_customers     = 1308
-- customer_churn_rate   = 21.80%
-- retention_rate        = 78.20%
-- total_mrr             = 487600
-- mrr_lost              = 107252
-- revenue_churn_rate    = 22.00%
-- arpu                  = 81.27


-- ============================================================
-- STAGE 4 TAKEAWAYS
-- ============================================================
-- 1. Overall customer churn is 21.8%.
-- 2. Revenue churn is approximately 22.0%.
-- 3. Month-to-month has the highest churn rate: 26.10%.
-- 4. Month-to-month accounts for $67,860 of MRR associated with churn,
--    approximately 63.3% of the total $107,252.
-- 5. Plan-tier churn is tightly clustered around 22%, so plan tier
--    alone is not a strong churn differentiator.
-- 6. Cohort retention can be used as a diagnostic before survival
--    analysis.
-- 7. The SQL risk-signal view is descriptive only; the final risk
--    score will be produced later using predictive modeling.
--
-- NEXT PROJECT STAGE:
-- Stage 5 = Statistical Inference
--   - Chi-square tests
--   - Point-biserial correlations
--   - Logistic regression for inference
-- ============================================================
