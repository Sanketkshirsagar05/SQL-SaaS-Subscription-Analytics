USE SaaS_Subscription_Analytics;
GO


-- 1.INDEXES FOR JOINS

-- Users → Subscriptions
CREATE INDEX idx_users_user_id
ON users(user_id);

CREATE INDEX idx_subscriptions_user_id
ON subscriptions(user_id);

-- Subscriptions → Payments
CREATE INDEX idx_payments_subscription_id
ON payments(subscription_id);

-- Subscriptions → Cancellations
CREATE INDEX idx_cancellations_subscription_id
ON cancellations(subscription_id);

-- Subscriptions → Plan Changes
CREATE INDEX idx_plan_changes_subscription_id
ON plan_changes(subscription_id);

-- Users → Usage Logs
CREATE INDEX idx_usage_logs_user_id
ON usage_logs(user_id);

-- 2.DATE-BASED ANALYTICS INDEXES

CREATE INDEX idx_payments_payment_date
ON payments(payment_date);

CREATE INDEX idx_usage_logs_activity_date
ON usage_logs(activity_date);

CREATE INDEX idx_cancellations_date
ON cancellations(cancellation_date);

-- 3.FILTER & GROUP-BY OPTIMIZATION

-- Payment Status Filtering
CREATE INDEX idx_payments_status
ON payments(payment_status);

-- Subscription Status Filtering
CREATE INDEX idx_subscriptions_status
ON subscriptions(subscription_status);

-- Country-Level Analytics
CREATE INDEX idx_users_country
ON users(country);

-- 4.COMPOSITE INDEXES (ADVANCED)

-- Payments: Subscription + Status
CREATE INDEX idx_payments_sub_status
ON payments(subscription_id, payment_status);

-- Usage Logs: User + Date
CREATE INDEX idx_usage_user_date
ON usage_logs(user_id, activity_date);



-- 1.Check Existing Indexes on All Tables
SELECT
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type
FROM sys.indexes i
JOIN sys.tables t
    ON i.object_id = t.object_id
WHERE i.is_primary_key = 0
  AND i.name IS NOT NULL
ORDER BY t.name;

-- 2.Find Tables Doing Full Scans (Missing Index Candidates)
SELECT
    OBJECT_NAME(s.object_id) AS table_name,
    s.user_scans,
    s.user_seeks,
    s.user_lookups
FROM sys.dm_db_index_usage_stats s
WHERE s.database_id = DB_ID()
ORDER BY s.user_scans DESC;

-- 3.Identify Unused Indexes (Index Cleanup)
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
    ON i.object_id = s.object_id
    AND i.index_id = s.index_id
    AND s.database_id = DB_ID()
WHERE i.is_primary_key = 0
  AND s.user_seeks IS NULL
  AND s.user_scans IS NULL;

-- 4.Find Queries That Benefit from Index on Payments
SELECT
    subscription_id,
    COUNT(*) AS payment_count
FROM payments
WHERE payment_status = 'Success'
GROUP BY subscription_id
ORDER BY payment_count DESC;

-- 5.Measure Impact of Date Index (Payments Trend)
SELECT
    FORMAT(payment_date, 'yyyy-MM') AS payment_month,
    COUNT(*) AS total_payments
FROM payments
WHERE payment_date >= DATEADD(
    MONTH,
    -6,
    (SELECT MAX(payment_date) FROM payments)
)
GROUP BY FORMAT(payment_date, 'yyyy-MM')
ORDER BY payment_month;

-- 6.Identify Heavy Join Tables
SELECT
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk;

-- 7.Check Index Fragmentation (Advanced – Very Impressive)
SELECT
    OBJECT_NAME(object_id) AS table_name,
    index_id,
    avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(
    DB_ID(),
    NULL,
    NULL,
    NULL,
    'LIMITED'
)
WHERE avg_fragmentation_in_percent > 20;

-- 8.Find Most Expensive Tables by Reads
SELECT
    OBJECT_NAME(object_id) AS table_name,
    SUM(user_seeks + user_scans + user_lookups) AS total_reads
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
GROUP BY object_id
ORDER BY total_reads DESC;

-- 9.Before–After Performance Explanation Query
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    u.country,
    SUM(p.amount)
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
JOIN payments p ON s.subscription_id = p.subscription_id
WHERE p.payment_status = 'Success'
GROUP BY u.country;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;