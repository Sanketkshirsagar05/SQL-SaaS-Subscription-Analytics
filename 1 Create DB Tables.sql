
--Create Database
CREATE DATABASE SaaS_Subscription_Analytics;
GO


USE SaaS_Subscription_Analytics;
GO

--Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE NOT NULL,
    country VARCHAR(50) NOT NULL,
    acquisition_channel VARCHAR(50) NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL
);
GO

--Plans Table     Done
CREATE TABLE plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL,
    billing_cycle VARCHAR(20) NOT NULL,
    price INT NOT NULL,
    is_active BIT NOT NULL
);
GO

--Subscriptions Table
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    subscription_status VARCHAR(20) NOT NULL,
    auto_renew BIT NOT NULL,

    CONSTRAINT fk_sub_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT fk_sub_plan
        FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);
GO

--Payments Table
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount INT NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,

    CONSTRAINT fk_pay_sub
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO


--Cancellations Table
CREATE TABLE cancellations (
    cancellation_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    cancellation_date DATE NOT NULL,
    cancellation_reason VARCHAR(50) NOT NULL,
    voluntary_flag BIT NOT NULL,

    CONSTRAINT fk_cancel_sub
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO


--Plan Changes Table
CREATE TABLE plan_changes (
    change_id INT PRIMARY KEY,
    subscription_id INT NOT NULL,
    old_plan_id INT NOT NULL,
    new_plan_id INT NOT NULL,
    change_date DATE NOT NULL,
    change_type VARCHAR(20) NOT NULL,

    CONSTRAINT fk_change_sub
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);
GO


--Usage Logs Table
CREATE TABLE usage_logs (
    usage_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    activity_date DATE NOT NULL,
    feature_used VARCHAR(50) NOT NULL,
    session_duration_minutes INT NOT NULL,

    CONSTRAINT fk_usage_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);
GO


--Support Tickets Table
CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    issue_type VARCHAR(50) NOT NULL,
    created_date DATE NOT NULL,
    resolved_date DATE NULL,
    ticket_status VARCHAR(30) NOT NULL,

    CONSTRAINT fk_ticket_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);
GO
