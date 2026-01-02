-- Interview Question

USE SaaS_Subscription_Analytics;
GO

-- 1.Find users who have never made a successful payment
SELECT DISTINCT u.user_id
FROM users u
LEFT JOIN subscriptions s ON u.user_id = s.user_id
LEFT JOIN payments p 
    ON s.subscription_id = p.subscription_id
    AND p.payment_status = 'Success'
WHERE p.payment_id IS NULL;


-- 2.Find subscriptions with failed payments only
SELECT s.subscription_id
FROM subscriptions s
JOIN payments p ON s.subscription_id = p.subscription_id
GROUP BY s.subscription_id
HAVING SUM(CASE WHEN p.payment_status = 'Success' THEN 1 ELSE 0 END) = 0;


-- 3.Get first payment date per user
SELECT
    u.user_id,
    MIN(p.payment_date) AS first_payment_date
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.user_id;


-- 4.Find users who upgraded more than once
SELECT
    subscription_id,
    COUNT(*) AS upgrade_count
FROM plan_changes
WHERE change_type = 'Upgrade'
GROUP BY subscription_id
HAVING COUNT(*) > 1;


-- 5.Identify inactive users who still have active subscriptions
SELECT DISTINCT
    u.user_id
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
WHERE u.status = 'Inactive'
  AND s.subscription_status = 'Active';


-- 6.Find the latest plan per subscription (Window Function)
WITH ranked_plans AS (
    SELECT
        subscription_id,
        new_plan_id,
        change_date,
        ROW_NUMBER() OVER (
            PARTITION BY subscription_id
            ORDER BY change_date DESC
        ) AS rn
    FROM plan_changes
)
SELECT
    subscription_id,
    new_plan_id AS latest_plan
FROM ranked_plans
WHERE rn = 1;


-- 7.Find subscriptions with no usage in last 90 days
SELECT DISTINCT s.subscription_id
FROM subscriptions s
JOIN users u ON s.user_id = u.user_id
LEFT JOIN usage_logs ul ON u.user_id = ul.user_id
GROUP BY s.subscription_id
HAVING MAX(ul.activity_date) < DATEADD(DAY, -90, GETDATE());


-- 8.Rank users by total session time
SELECT
    user_id,
    SUM(session_duration_minutes) AS total_minutes,
    RANK() OVER (ORDER BY SUM(session_duration_minutes) DESC) AS user_rank
FROM usage_logs
GROUP BY user_id;


-- 9.Find top 3 plans per country by subscriber count
SELECT *
FROM (
    SELECT
        u.country,
        p.plan_name,
        COUNT(*) AS subs_count,
        RANK() OVER (
            PARTITION BY u.country
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM users u
    JOIN subscriptions s ON u.user_id = s.user_id
    JOIN plans p ON s.plan_id = p.plan_id
    GROUP BY u.country, p.plan_name
) x
WHERE rnk <= 3;


-- 10.Find users who raised support tickets before cancelling
SELECT DISTINCT
    s.subscription_id
FROM subscriptions s
JOIN cancellations c ON s.subscription_id = c.subscription_id
JOIN support_tickets t ON s.user_id = t.user_id
WHERE t.created_date < c.cancellation_date;


-- 11.Identify subscriptions with payment gaps (Missing months)
SELECT
    subscription_id,
    COUNT(DISTINCT FORMAT(payment_date, 'yyyy-MM')) AS paid_months
FROM payments
WHERE payment_status = 'Success'
GROUP BY subscription_id
HAVING COUNT(DISTINCT FORMAT(payment_date, 'yyyy-MM')) < 3;


-- 12.Find users with multiple concurrent subscriptions
SELECT
    user_id,
    COUNT(*) AS active_subs
FROM subscriptions
WHERE subscription_status = 'Active'
GROUP BY user_id
HAVING COUNT(*) > 1;


-- 13.Find most common cancellation reason per plan
SELECT *
FROM (
    SELECT
        p.plan_name,
        c.cancellation_reason,
        COUNT(*) AS cnt,
        RANK() OVER (
            PARTITION BY p.plan_name
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM cancellations c
    JOIN subscriptions s ON c.subscription_id = s.subscription_id
    JOIN plans p ON s.plan_id = p.plan_id
    GROUP BY p.plan_name, c.cancellation_reason
) x
WHERE rnk = 1;


-- 14.Detect subscriptions that downgraded after upgrading
SELECT DISTINCT pc1.subscription_id
FROM plan_changes pc1
JOIN plan_changes pc2
    ON pc1.subscription_id = pc2.subscription_id
WHERE pc1.change_type = 'Upgrade'
  AND pc2.change_type = 'Downgrade'
  AND pc2.change_date > pc1.change_date;



-- 15.Find users whose usage dropped by 50% month-over-month
WITH monthly_usage AS (
    SELECT
        user_id,
        FORMAT(activity_date, 'yyyy-MM') AS month,
        SUM(session_duration_minutes) AS usage_time
    FROM usage_logs
    GROUP BY user_id, FORMAT(activity_date, 'yyyy-MM')
),
usage_change AS (
    SELECT
        user_id,
        month,
        usage_time,
        LAG(usage_time) OVER (
            PARTITION BY user_id
            ORDER BY month
        ) AS prev_usage
    FROM monthly_usage
)
SELECT *
FROM usage_change
WHERE prev_usage IS NOT NULL
  AND usage_time < prev_usage * 0.5;