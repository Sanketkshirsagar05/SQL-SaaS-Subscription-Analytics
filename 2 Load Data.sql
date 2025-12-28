USE SaaS_Subscription_Analytics;
GO

-- Master / Dimension tables
:r "...\\Data\\plans.sql"
:r "...\\Data\\users.sql"

-- Core transactional tables
:r "...\\Data\\subscriptions.sql"

-- Dependent tables
:r "...\\Data\\payments.sql"
:r "...\\Data\\cancellations.sql"
:r "...\\Data\\plan_changes.sql"
:r "...\\Data\\usage_logs.sql"
:r "...\\Data\\support_tickets.sql"
GO
