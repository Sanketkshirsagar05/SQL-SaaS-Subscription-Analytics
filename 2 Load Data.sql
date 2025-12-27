USE SaaS_Subscription_Analytics;
GO

--  Master / Dimension tables first
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\plans.sql"
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\users.sql"

--  Core transactional tables
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\subscriptions.sql"

--  Dependent tables
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\payments.sql"
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\cancellations.sql"
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\plan_changes.sql"
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\usage_logs.sql"
:r "E:\Desktop\Excelr\Projects\DA Project\SQL\5 SQL SaaS Subscription Analytics\Data\support_tickets.sql"
GO
