
--Create Database
CREATE DATABASE SaaS_Subscription_Analytics;
GO


USE SaaS_Subscription_Analytics;
GO

--Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    country VARCHAR(50),
    acquisition_channel VARCHAR(50),
    user_type VARCHAR(20),
    status VARCHAR(20)
);
GO

--Plans Table     Done
CREATE TABLE plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50),
    billing_cycle VARCHAR(20),
    price INT,
    is_active BIT
);
GO

--Subscriptions Table
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    start_date DATE,
    end_date DATE,
    subscription_status VARCHAR(20),
    auto_renew BIT DEFAULT 1,
    CONSTRAINT fk_sub_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_sub_plan FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);
GO

--Payments Table
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    payment_date DATE,
    amount INT,
    payment_status VARCHAR(20),
    payment_method VARCHAR(20),
    CONSTRAINT fk_pay_sub FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO

--Cancellations Table
CREATE TABLE cancellations (
    cancellation_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    cancellation_date DATE,
    cancellation_reason VARCHAR(50),
    voluntary_flag BIT,
    CONSTRAINT fk_cancel_sub FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO

--Plan Changes Table
CREATE TABLE plan_changes (
    change_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    old_plan_id INT,
    new_plan_id INT,
    change_date DATE,
    change_type VARCHAR(20),
    CONSTRAINT fk_change_sub FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO

--Usage Logs Table
CREATE TABLE usage_logs (
    usage_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    activity_date DATE,
    feature_used VARCHAR(50),
    session_duration_minutes INT,
    CONSTRAINT fk_usage_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);
GO

--Support Tickets Table
CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    issue_type VARCHAR(50),
    created_date DATE,
    resolved_date DATE,
    ticket_status VARCHAR(30),
    CONSTRAINT fk_ticket_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);
GO
