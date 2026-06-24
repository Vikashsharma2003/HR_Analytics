USE hr_analytics;
SET SESSION wait_timeout = 28800;
SET SESSION net_read_timeout = 3600;
SET SESSION net_write_timeout = 3600;

-- materalizing the view for fast work 
DROP TABLE IF EXISTS tbl_employees;
CREATE TABLE tbl_employees AS
SELECT * FROM employees_clean;


-- creating businee view for attrion problem
CREATE OR REPLACE VIEW attrition_view AS 
SELECT 
     *,-- selecting every column from employees table 
     ROUND(
     CASE
	 WHEN exit_date IS NOT NULL
     AND joining_date>exit_date THEN NULL
     WHEN employee_status = 'Active' THEN DATEDIFF(CURDATE(),joining_date)/365 -- computing tenure of active employee
     ELSE DATEDIFF(exit_date,joining_date)/365 -- computing tenure of non-active employee
     END ,2) AS Tenure_years
     
     FROM tbl_employees;
     
-- droping table for refreshing the data
	DROP TABLE IF EXISTS final_employees;
    -- creating final table for attrition problem as final_employees from attrition_view
    CREATE TABLE final_employees AS 
	SELECT * FROM attrition_view;


DROP TABLE IF EXISTS tbl_payroll;
CREATE TABLE tbl_payroll AS
SELECT * FROM payroll_clean;

DROP TABLE IF EXISTS tbl_performance;
CREATE TABLE tbl_performance AS
SELECT * FROM performance_clean;
-- creating final table for problem 2 

-- creating view of fair pay table   
CREATE OR REPLACE VIEW Fair_pay_view AS
WITH latest_review AS (
    SELECT 
        employee_id,
        MAX(review_year) AS max_year
    FROM tbl_performance
    GROUP BY employee_id
),
avg_payroll AS (
    SELECT 
        employee_id,
        ROUND(AVG(gross_salary), 2) AS avg_salary,
        ROUND(AVG(bonus), 2) AS avg_bonus
    FROM tbl_payroll
    GROUP BY employee_id
)
SELECT
    e.employee_id,
    e.department,
    e.gender,
    e.job_role,
    p.avg_salary,
    p.avg_bonus,
    pf.performance_rating,
    pf.promotion_status,
    pf.training_hours
FROM tbl_employees e
LEFT JOIN avg_payroll p 
    ON e.employee_id = p.employee_id
LEFT JOIN latest_review lr 
    ON e.employee_id = lr.employee_id
LEFT JOIN tbl_performance pf 
    ON e.employee_id = pf.employee_id
    AND pf.review_year = lr.max_year;

-- droping table for refreshing the data
	DROP TABLE IF EXISTS final_Fair_pay;
    -- creating final table for Fair_pay problem as final_Fair_pay from Fair_pay_view
    CREATE TABLE final_Fair_pay AS 
	SELECT * FROM Fair_pay_view;
 
 -- materalizing the view for fast work 
DROP TABLE IF EXISTS tbl_attendance;
CREATE TABLE tbl_attendance AS
SELECT * FROM attendance_clean;

-- Business View: Attendance vs Performance Analysis
-- Purpose: Analyze if attendance patterns affect performance ratings
-- Tables used: tbl_attendance, tbl_performance, tbl_employees
CREATE OR REPLACE VIEW attendance_performance_view AS
WITH yearly_attendance AS (
    -- Converting daily attendance to yearly averages per employee
    -- Also calculating % of days spent in each work mode
    SELECT 
        employee_id,
        YEAR(attendance_date) AS attendance_year,
        ROUND(AVG(attendance_percent), 2) AS avg_attendance,
        ROUND(SUM(CASE WHEN work_mode = 'WFH' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS wfh_pct,
        ROUND(SUM(CASE WHEN work_mode = 'Office' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS office_pct,
        ROUND(SUM(CASE WHEN work_mode = 'Hybrid' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS hybrid_pct
    FROM tbl_attendance
    GROUP BY employee_id, YEAR(attendance_date)
),
latest_review AS (
    -- Getting most recent review year per employee
    -- Some employees may not have 2025 review so using MAX year
    SELECT 
        employee_id,
        MAX(review_year) AS max_year
    FROM tbl_performance
    GROUP BY employee_id
)
SELECT
    ya.employee_id,
    e.department,
    e.gender,
    e.job_role,
    ya.avg_attendance,          -- average attendance % for the year
    ya.wfh_pct,                 -- % days worked from home
    ya.office_pct,              -- % days worked from office
    ya.hybrid_pct,              -- % days worked hybrid
    pf.performance_rating,      -- latest performance rating
    pf.promotion_status         -- promotion decision
FROM yearly_attendance ya
LEFT JOIN tbl_employees e 
    ON ya.employee_id = e.employee_id  -- adding employee context
LEFT JOIN latest_review lr 
    ON ya.employee_id = lr.employee_id  -- bringing in latest review year
LEFT JOIN tbl_performance pf 
    ON ya.employee_id = pf.employee_id
    AND pf.review_year = lr.max_year;  -- matching only latest review year


-- droping table for refreshing the data
	DROP TABLE IF EXISTS final_attendance_performance;
    -- creating final table for Fair_pay problem as final_Fair_pay from Fair_pay_view
    CREATE TABLE  final_attendance_performance AS 
	SELECT * FROM attendance_performance_view;
 
 -- Business View: Promotion Fairness Analysis
-- Purpose: Analyze if high performers are being promoted fairly
-- Tables used: tbl_employees, tbl_performance
-- Granularity: One row per employee per review year
-- All years included to calculate promotion rate over time

-- creating view of promotion_fairness table 
CREATE OR REPLACE VIEW promotion_fairness_view AS
SELECT
    e.employee_id,
    e.department,
    e.gender,
    e.job_role,
    pf.review_year,           -- year of performance review
    pf.performance_rating,    -- rating 1-5
    pf.promotion_status,      -- Promoted or Not Promoted
    pf.training_hours         -- training hours that year
FROM tbl_employees e
LEFT JOIN tbl_performance pf
    ON e.employee_id = pf.employee_id; -- joining on employee_id
    
    
    
-- droping table for refreshing the data
	DROP TABLE IF EXISTS final_promotion_fairness;
    -- creating final table for Fair_pay problem as final_Fair_pay from Fair_pay_view
    CREATE TABLE final_promotion_fairness AS 
	SELECT * FROM promotion_fairness_view;