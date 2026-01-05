
USE SaaS_Subscription_Analytics;
GO

-- 1.Orphan Records (FK Validation)

--Subscriptions without Users
SELECT 
    COUNT(*) AS orphan_subscriptions
FROM subscriptions s
LEFT JOIN users u ON s.user_id = u.user_id
WHERE u.user_id IS NULL;

--Payments without Subscriptions
SELECT 
    COUNT(*) AS orphan_payments
FROM payments p
LEFT JOIN subscriptions s ON p.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL;

-- 2.Date Integrity Checks

-- End Date Before Start Date
SELECT 
    COUNT(*) AS invalid_subscription_dates
FROM subscriptions
WHERE end_date IS NOT NULL
  AND end_date < start_date;

-- Payments Before Subscription Start
SELECT 
    COUNT(*) AS early_payments
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.subscription_id
WHERE p.payment_date < s.start_date;

-- 3.Status Consistency Checks

-- Cancelled Subscriptions Missing Cancellation Record
SELECT 
    COUNT(*) AS missing_cancellations
FROM subscriptions s
LEFT JOIN cancellations c ON s.subscription_id = c.subscription_id
WHERE s.subscription_status = 'Cancelled'
  AND c.subscription_id IS NULL;

-- Cancellation Exists but Subscription Still Active
SELECT 
    COUNT(*) AS invalid_cancellation_status
FROM cancellations c
JOIN subscriptions s ON c.subscription_id = s.subscription_id
WHERE s.subscription_status <> 'Cancelled';

-- 4.Revenue Validations

-- Successful Payments with Zero Amount
SELECT 
    COUNT(*) AS zero_amount_success_payments
FROM payments
WHERE payment_status = 'Success'
  AND amount = 0;

-- Negative Payment Amounts
SELECT 
    COUNT(*) AS negative_payments
FROM payments
WHERE amount < 0;

-- 5.Duplicate Detection
SELECT 
    COUNT(*) AS duplicate_payment_groups
FROM (
    SELECT subscription_id, payment_date, amount
    FROM payments
    GROUP BY subscription_id, payment_date, amount
    HAVING COUNT(*) > 1
) d;

-- 6.User-Level Quality Checks

-- Inactive Users with Activity
SELECT 
    COUNT(DISTINCT u.user_id) AS inactive_users_with_usage
FROM users u
JOIN usage_logs ul ON u.user_id = ul.user_id
WHERE u.status = 'Inactive';

-- Active Users Without Subscriptions
SELECT 
    COUNT(*) AS active_users_without_subscription
FROM users u
LEFT JOIN subscriptions s ON u.user_id = s.user_id
WHERE u.status = 'Active'
  AND s.subscription_id IS NULL;

-- 7.Plan Change Integrity
SELECT 
    COUNT(*) AS invalid_plan_changes
FROM plan_changes
WHERE old_plan_id = new_plan_id;
