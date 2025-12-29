USE SaaS_Subscription_Analytics;
GO

-- 1.BASIC HEALTH METRICS

-- Total Users
SELECT COUNT(*) AS total_users
FROM users;

-- Active vs Inactive Users
SELECT status, COUNT(*) AS users_count
FROM users
GROUP BY status;

-- Active Subscriptions
SELECT COUNT(*) AS active_subscriptions
FROM subscriptions
WHERE subscription_status = 'Active';


-- 2.REVENUE ANALYSIS

-- Total Revenue
SELECT SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'Success';

-- Revenue by Plan
SELECT
    p.plan_name,
    SUM(pay.amount) AS revenue
FROM payments pay
JOIN subscriptions s ON pay.subscription_id = s.subscription_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE pay.payment_status = 'Success'
GROUP BY p.plan_name
ORDER BY revenue DESC;

-- Monthly Revenue Trend
SELECT
    FORMAT(payment_date, 'yyyy-MM') AS revenue_month,
    SUM(amount) AS monthly_revenue
FROM payments
WHERE payment_status = 'Success'
GROUP BY FORMAT(payment_date, 'yyyy-MM')
ORDER BY revenue_month;

-- 3.MRR (MONTHLY RECURRING REVENUE)
SELECT
    FORMAT(payment_date, 'yyyy-MM') AS month,
    SUM(amount) AS MRR
FROM payments
WHERE payment_status = 'Success'
GROUP BY FORMAT(payment_date, 'yyyy-MM')
ORDER BY month;

-- 4.CHURN ANALYSIS

-- Total Churned Subscriptions
SELECT COUNT(*) AS churned_subscriptions
FROM subscriptions
WHERE subscription_status = 'Cancelled';

-- Churn Rate (%)
SELECT
    CAST(
        COUNT(CASE WHEN subscription_status = 'Cancelled' THEN 1 END) * 100.0
        / COUNT(*) AS DECIMAL(5,2)
    ) AS churn_rate_percentage
FROM subscriptions;

-- Churn by Reason
SELECT
    cancellation_reason,
    COUNT(*) AS churn_count
FROM cancellations
GROUP BY cancellation_reason
ORDER BY churn_count DESC;


-- 5.GEOGRAPHICAL ANALYSIS

-- Users by Country
SELECT country, COUNT(*) AS users_count
FROM users
GROUP BY country
ORDER BY users_count DESC;

-- Revenue by Country
SELECT
    u.country,
    SUM(p.amount) AS revenue
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.country
ORDER BY revenue DESC;

-- 6.UPGRADE / DOWNGRADE ANALYSIS

-- Upgrade vs Downgrade Count
SELECT change_type, COUNT(*) AS total_changes
FROM plan_changes
GROUP BY change_type;

-- Most Common Upgrade Path
SELECT
    old_plan_id,
    new_plan_id,
    COUNT(*) AS change_count
FROM plan_changes
WHERE change_type = 'Upgrade'
GROUP BY old_plan_id, new_plan_id
ORDER BY change_count DESC;


-- 7.USER ENGAGEMENT ANALYSIS

-- Most Used Features
SELECT
    feature_used,
    COUNT(*) AS usage_count
FROM usage_logs
GROUP BY feature_used
ORDER BY usage_count DESC;

-- Average Session Duration
SELECT
    AVG(session_duration_minutes) AS avg_session_minutes
FROM usage_logs;

-- Active Users (Used Product in Last 30 Days)
SELECT COUNT(DISTINCT user_id) AS active_users_last_30_days
FROM usage_logs
WHERE activity_date >= DATEADD(DAY, -30, GETDATE());


-- 8.SUPPORT & EXPERIENCE ANALYSIS

-- Total Support Tickets
SELECT COUNT(*) AS total_tickets
FROM support_tickets;

-- Tickets by Status
SELECT ticket_status, COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY ticket_status;

-- Avg Resolution Time (Days)
SELECT
    AVG(DATEDIFF(DAY, created_date, resolved_date)) AS avg_resolution_days
FROM support_tickets
WHERE resolved_date IS NOT NULL;


-- 9.TOP CUSTOMERS

-- Top 10 Revenue Generating Users
SELECT TOP 10
    u.user_id,
    SUM(p.amount) AS total_spent
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.user_id
ORDER BY total_spent DESC;

-- 10.SUBSCRIPTION LIFECYCLE

-- Avg Subscription Duration (Days)
SELECT
    AVG(DATEDIFF(DAY, start_date, ISNULL(end_date, GETDATE()))) AS avg_subscription_days
FROM subscriptions;



