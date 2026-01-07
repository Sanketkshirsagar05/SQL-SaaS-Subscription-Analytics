USE SaaS_Subscription_Analytics;
GO

-- 1.View: Active Subscriptions (Core Business Entity)
CREATE VIEW vw_active_subscriptions AS
SELECT
    s.subscription_id,
    s.user_id,
    s.plan_id,
    s.start_date,
    s.auto_renew
FROM subscriptions s
WHERE s.subscription_status = 'Active';
GO


-- 2.View: User + Subscription + Plan (Flattened View)

CREATE VIEW vw_user_subscription_plan AS
SELECT
    u.user_id,
    u.signup_date,
    u.country,
    u.acquisition_channel,
    s.subscription_id,
    s.subscription_status,
    p.plan_name,
    p.price
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN plans p ON s.plan_id = p.plan_id;
GO

-- 3.View: Successful Payments Only

CREATE VIEW vw_successful_payments AS
SELECT
    payment_id,
    subscription_id,
    payment_date,
    amount
FROM payments
WHERE payment_status = 'Success';
GO


-- 4,View: Monthly Revenue (Data-Date Anchored)

CREATE VIEW vw_monthly_revenue AS
SELECT
    FORMAT(payment_date, 'yyyy-MM') AS revenue_month,
    SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'Success'
GROUP BY FORMAT(payment_date, 'yyyy-MM');
GO


-- 5.View: Churned Subscriptions with Reason

CREATE VIEW vw_churn_details AS
SELECT
    s.subscription_id,
    s.user_id,
    c.cancellation_date,
    c.cancellation_reason
FROM subscriptions s
JOIN cancellations c
    ON s.subscription_id = c.subscription_id;
GO


-- 6.View: User Engagement Summary

CREATE VIEW vw_user_engagement AS
SELECT
    user_id,
    COUNT(*) AS total_sessions,
    SUM(session_duration_minutes) AS total_minutes,
    MAX(activity_date) AS last_activity_date
FROM usage_logs
GROUP BY user_id;
GO


-- 7.View: Upgrade & Downgrade History

CREATE VIEW vw_plan_change_history AS
SELECT
    pc.subscription_id,
    pc.change_date,
    pc.change_type,
    p1.plan_name AS old_plan,
    p2.plan_name AS new_plan
FROM plan_changes pc
JOIN plans p1 ON pc.old_plan_id = p1.plan_id
JOIN plans p2 ON pc.new_plan_id = p2.plan_id;
GO


-- 8.View: Country-Level Revenue

CREATE VIEW vw_country_revenue AS
SELECT
    u.country,
    SUM(p.amount) AS revenue
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.country;
GO

-- 1.Find Active Subscriptions Count by Plan

SELECT
    p.plan_name,
    COUNT(v.subscription_id) AS active_subscriptions
FROM vw_active_subscriptions v
JOIN plans p ON v.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY active_subscriptions DESC;


-- 2.Top 5 Countries by Revenue (Using View)

SELECT TOP 5
    country,
    revenue
FROM vw_country_revenue
ORDER BY revenue DESC;


-- 3.Users With High Engagement but No Active Subscription

SELECT
    e.user_id,
    e.total_sessions,
    e.total_minutes
FROM vw_user_engagement e
LEFT JOIN vw_active_subscriptions a
    ON e.user_id = a.user_id
WHERE a.subscription_id IS NULL
  AND e.total_sessions > 10;


-- 4.Revenue Contribution by Plan Using Views

SELECT
    usp.plan_name,
    SUM(p.amount) AS revenue
FROM vw_user_subscription_plan usp
JOIN vw_successful_payments p
    ON usp.subscription_id = p.subscription_id
GROUP BY usp.plan_name
ORDER BY revenue DESC;

-- 5.Churn Analysis: Cancellation Count by Reason

SELECT
    cancellation_reason,
    COUNT(*) AS churn_count
FROM vw_churn_details
GROUP BY cancellation_reason
ORDER BY churn_count DESC;