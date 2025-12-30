USE SaaS_Subscription_Analytics;
GO

-- 1.MRR GROWTH (MoM – Window Function)
WITH monthly_mrr AS (
    SELECT
        FORMAT(payment_date, 'yyyy-MM') AS month,
        SUM(amount) AS mrr
    FROM payments
    WHERE payment_status = 'Success'
    GROUP BY FORMAT(payment_date, 'yyyy-MM')
)
SELECT
    month,
    mrr,
    mrr - LAG(mrr) OVER (ORDER BY month) AS mom_change,
    CAST(
        (mrr - LAG(mrr) OVER (ORDER BY month)) * 100.0 /
        NULLIF(LAG(mrr) OVER (ORDER BY month), 0)
        AS DECIMAL(10,2)
    ) AS mom_growth_pct
FROM monthly_mrr
ORDER BY month;

-- 2.COHORT ANALYSIS (User Retention)
WITH user_cohort AS (
    SELECT
        user_id,
        FORMAT(MIN(start_date), 'yyyy-MM') AS cohort_month
    FROM subscriptions
    GROUP BY user_id
),
activity AS (
    SELECT DISTINCT
        ul.user_id,
        uc.cohort_month,
        FORMAT(ul.activity_date, 'yyyy-MM') AS activity_month
    FROM usage_logs ul
    JOIN user_cohort uc
        ON ul.user_id = uc.user_id
)
SELECT
    cohort_month,
    activity_month,
    COUNT(DISTINCT user_id) AS active_users
FROM activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;

-- 3.CHURN TREND OVER TIME
SELECT
    FORMAT(c.cancellation_date, 'yyyy-MM') AS month,
    COUNT(*) AS churned_subscriptions
FROM cancellations c
GROUP BY FORMAT(c.cancellation_date, 'yyyy-MM')
ORDER BY month;

-- 4.CUSTOMER LIFETIME VALUE (CLV)
SELECT
    u.user_id,
    SUM(p.amount) AS lifetime_value
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.user_id
ORDER BY lifetime_value DESC;

-- 5.CHURN PREDICTION SIGNAL (LOW USAGE)
WITH last_activity AS (
    SELECT
        user_id,
        MAX(activity_date) AS last_used
    FROM usage_logs
    GROUP BY user_id
)
SELECT
    u.user_id,
    u.status,
    la.last_used
FROM users u
LEFT JOIN last_activity la ON u.user_id = la.user_id
WHERE la.last_used < DATEADD(DAY, -60, GETDATE());

-- 6.EXPANSION vs CONTRACTION MRR
SELECT
    pc.change_type,
    SUM(p2.price - p1.price) AS revenue_change
FROM plan_changes pc
JOIN plans p1 ON pc.old_plan_id = p1.plan_id
JOIN plans p2 ON pc.new_plan_id = p2.plan_id
GROUP BY pc.change_type;

-- 7.POWER USERS (Top 20% by Usage)
WITH user_usage AS (
    SELECT
        user_id,
        COUNT(*) AS sessions
    FROM usage_logs
    GROUP BY user_id
),
ranked_users AS (
    SELECT
        user_id,
        sessions,
        NTILE(5) OVER (ORDER BY sessions DESC) AS usage_bucket
    FROM user_usage
)
SELECT
    user_id,
    sessions
FROM ranked_users
WHERE usage_bucket = 1;

-- 8.AVERAGE REVENUE PER USER (ARPU)
SELECT
    CAST(
        SUM(amount) * 1.0 /
        COUNT(DISTINCT s.user_id)
        AS DECIMAL(10,2)
    ) AS ARPU
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.subscription_id
WHERE p.payment_status = 'Success';

-- 9.TIME TO CHURN (IN DAYS)
SELECT
    AVG(DATEDIFF(DAY, s.start_date, c.cancellation_date)) AS avg_days_to_churn
FROM subscriptions s
JOIN cancellations c ON s.subscription_id = c.subscription_id;

-- 10.PLAN RETENTION RATE
WITH plan_users AS (
    SELECT
        plan_id,
        COUNT(DISTINCT subscription_id) AS total_subs,
        COUNT(DISTINCT CASE WHEN subscription_status = 'Active' THEN subscription_id END) AS active_subs
    FROM subscriptions
    GROUP BY plan_id
)
SELECT
    p.plan_name,
    CAST(active_subs * 100.0 / total_subs AS DECIMAL(5,2)) AS retention_rate_pct
FROM plan_users pu
JOIN plans p ON pu.plan_id = p.plan_id;