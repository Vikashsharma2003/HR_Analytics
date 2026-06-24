CREATE DATABASE IF NOT EXISTS hr_analytics;

USE hr_analytics;


-- raw employee table
CREATE TABLE IF NOT EXISTS Raw_employees (
    employee_id VARCHAR(15),
    employee_name VARCHAR(100),
    gender VARCHAR(10),
    department VARCHAR(50),
    job_role VARCHAR(100),
    city VARCHAR(50),
    manager_id VARCHAR(15),
    joining_date VARCHAR(20),
    employee_status VARCHAR(20),
    exit_date VARCHAR(20),
    monthly_salary VARCHAR(20)
);
-- load data into employee table 
TRUNCATE TABLE Raw_employees;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employees.csv'
INTO TABLE  Raw_employees
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- raw attendance table
CREATE TABLE IF NOT EXISTS Raw_attendance (
    employee_id VARCHAR(15),
    attendance_date VARCHAR(20),
    attendance_percent VARCHAR(20),
    work_mode VARCHAR(20)
);
-- load data to attendance table
TRUNCATE TABLE Raw_attendance;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/attendance.csv'
INTO TABLE Raw_attendance
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- raw payroll table
CREATE TABLE IF NOT EXISTS Raw_payroll (
    employee_id VARCHAR(15),
    salary_month VARCHAR(20),
    gross_salary VARCHAR(20),
    bonus VARCHAR(20),
    tax_deduction VARCHAR(20)
);

-- load data into payroll table
TRUNCATE TABLE Raw_payroll;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payroll.csv'
INTO TABLE  Raw_payroll
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- raw performance table
CREATE TABLE IF NOT EXISTS Raw_performance (
    employee_id VARCHAR(15),
    review_year VARCHAR(10),
    performance_rating VARCHAR(10),
    promotion_status VARCHAR(20),
    training_hours VARCHAR(10)
);
-- load data into performance table
TRUNCATE TABLE Raw_performance;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/performance.csv'
INTO TABLE  Raw_performance
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


