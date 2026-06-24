USE hr_analytics;

-- ////////// AUDIT FILE //////////

-- Raw_employees
SELECT * FROM Raw_employees;

SELECT COUNT(*) FROM Raw_employees; 
-- total rows in raw file 51200

SELECT COUNT(employee_id) - COUNT( DISTINCT employee_id) AS duplicate_rows
FROM Raw_employees; 
-- 1200 duplicate rows

SELECT COUNT(*) FROM Raw_employees
WHERE TRIM(employee_id) ='' OR employee_id IS NULL ;

-- 0 NULL EMPLOYEE ID 

SELECT DISTINCT gender COLLATE utf8mb4_bin
FROM Raw_employees; 
-- MALE AND FEMALE 2 VALUES

SELECT DISTINCT department COLLATE utf8mb4_bin
FROM Raw_employees;
-- multiple value for same department

SELECT DISTINCT job_role COLLATE utf8mb4_bin
FROM Raw_employees;
-- no standardization is needed

SELECT DISTINCT city COLLATE utf8mb4_bin
FROM Raw_employees;
-- no standardization is needed

SELECT employee_id
FROM Raw_employees
WHERE TRIM(manager_id) ='' OR manager_id IS NULL ;
-- no blank or null manager_id 

SELECT 
    CASE
        WHEN joining_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'YYYY-MM-DD'
        WHEN joining_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 'DD-MM-YYYY'
        WHEN joining_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'DD/MM/YYYY'
        WHEN joining_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN 'YYYY/MM/DD'
        WHEN joining_date REGEXP '^[0-9]{2} [A-Za-z]{3} [0-9]{4}$' THEN 'DD Mon YYYY'
        ELSE 'Other / Invalid'
    END AS detected_format,
    COUNT(*) AS total_rows
FROM
    Raw_employees
GROUP BY detected_format
ORDER BY total_rows DESC;

-- YYYY-MM-DD 48200 AND DD-MM-YYYY 3000 FOUND


SELECT DISTINCT employee_status COLLATE utf8mb4_bin
FROM Raw_employees;
-- no standardization is needed

SELECT 
    CASE
        WHEN exit_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'YYYY-MM-DD'
        WHEN exit_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 'DD-MM-YYYY'
        WHEN exit_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'DD/MM/YYYY'
        WHEN exit_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN 'YYYY/MM/DD'
        WHEN exit_date REGEXP '^[0-9]{2} [A-Za-z]{3} [0-9]{4}$' THEN 'DD Mon YYYY'
        WHEN TRIM(exit_date) = '' THEN 'BLANK'
        ELSE 'Other / Invalid'
    END AS detected_format,
    COUNT(*) AS total_rows
FROM
    Raw_employees
GROUP BY detected_format
ORDER BY total_rows DESC;
-- YYYY-MM-DD 6763 DD/MM/YYYY 2458 AND 41979 as this number of employee is still active

SELECT
    MAX(CAST(monthly_salary AS DECIMAL(10,2))) AS MAX_SALARY,
    MIN(CAST(monthly_salary AS DECIMAL(10,2))) AS MIN_SALARY,
    AVG(CAST(monthly_salary AS DECIMAL(10,2))) AS AVG_SALARY
FROM Raw_employees;
-- FOUND NEGATIVE VALUE WHICH IS ENTRY ERROR


-- Raw_attendance

SELECT * FROM Raw_attendance;

SELECT COUNT(*) FROM Raw_attendance;

-- 70000 ROWS in raw file

SELECT COUNT(DISTINCT employee_id) FROM Raw_attendance ;
-- 37709 distinct value 

SELECT COUNT(*) AS Duplicate_Count
FROM(
SELECT employee_id,attendance_date, COUNT(*)
FROM Raw_attendance
GROUP BY employee_id,attendance_date
HAVING COUNT(*)>1) AS Duplicates
;
-- 130 duplicate rows 
-- issue all rows are not identical 

SELECT COUNT(*) FROM Raw_attendance
WHERE TRIM(employee_id) = '' OR employee_id IS NULL;
-- 0 Invalid Value in employee_id

SELECT COUNT(*) FROM Raw_attendance
WHERE TRIM(attendance_date) = '' OR attendance_date IS NULL;
-- 0 Blank OR null attendance_date

SELECT 
    CASE
        WHEN attendance_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'YYYY-MM-DD'
        WHEN attendance_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 'DD-MM-YYYY'
        WHEN attendance_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'DD/MM/YYYY'
        WHEN attendance_date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN 'YYYY/MM/DD'
        WHEN attendance_date REGEXP '^[0-9]{2} [A-Za-z]{3} [0-9]{4}$' THEN 'DD Mon YYYY'
        ELSE 'Other / Invalid'
    END AS detected_format,
    COUNT(*) AS total_rows
FROM
    Raw_attendance
GROUP BY detected_format
ORDER BY total_rows DESC;

-- All are in one format but can add format for future safety

SELECT 
   CASE 
   WHEN TRIM(attendance_percent) = '' THEN 'Blank'
   WHEN attendance_percent IS NULL THEN NULL
   WHEN TRIM(attendance_percent) REGEXP'[%]' THEN '% Symbol'
   WHEN CAST(TRIM(attendance_percent) AS DECIMAL(5,2)) <0 OR CAST(TRIM(attendance_percent) AS DECIMAL(5,2)) >100  THEN 'Outliers'
   ELSE 'VALID'
   END AS detected_issue,
   COUNT(*) AS Total_rows
   FROM Raw_attendance
   GROUP BY detected_issue
   ORDER BY Total_rows DESC ;
-- 69850 Valid values 
-- 150 outliers

SELECT DISTINCT work_mode COLLATE utf8mb4_bin
FROM Raw_attendance;
-- NO STANDARDIZATION NEED IN work_mode


-- //////// payroll  file 

SELECT COUNT(*) FROM raw_payroll ;
-- 51200 total rows in payroll file

SELECT COUNT(DISTINCT CONCAT(employee_id, salary_month)) 
FROM raw_payroll;

-- 50909 UNIQUE employee_id  

SELECT COUNT(*) FROM(
SELECT employee_id,salary_month,COUNT(*)
FROM raw_payroll
GROUP BY employee_id,salary_month
HAVING COUNT(*)>1) AS D;

-- Duplicate rows: 291 (0.5%)
-- Decision: Keep row with highest bonus

SELECT COUNT(DISTINCT salary_month) FROM raw_payroll;
-- 4 months are present where salary are given(2025-01-2025-04)

SELECT * FROM raw_payroll
WHERE TRIM(salary_month) = '' OR salary_month IS NULL ;
-- no NULL or blank value in salary_month


SELECT
    MAX(CAST(gross_salary AS DECIMAL(10,2))) AS MAX_gross_salary,
    MIN(CAST(gross_salary AS DECIMAL(10,2))) AS MIN_gross_salary,
    AVG(CAST(gross_salary AS DECIMAL(10,2))) AS AVG_gross_salary
FROM raw_payroll;

-- issue NEGATIVE value found in gross_salary 

SELECT COUNT(*) FROM raw_payroll
WHERE TRIM(bonus) = '' OR bonus IS NULL;
-- 0 blank value in bonus

SELECT
    MAX(CAST(bonus AS DECIMAL(10,2))) AS MAX_bonus,
    MIN(CAST(bonus AS DECIMAL(10,2))) AS MIN_bonus,
    AVG(CAST(bonus AS DECIMAL(10,2))) AS AVG_bonus
FROM raw_payroll;
-- found issue in bonus as minimum bonus is 2 which is very low

SELECT 
CASE
 WHEN bonus_clean = 0 THEN 'Zero'
 WHEN bonus_clean BETWEEN 1 AND 99 THEN '1-99'
 WHEN bonus_clean BETWEEN 100 AND 499 THEN '100-499'
 WHEN bonus_clean BETWEEN 500 AND 999 THEN '500-999'
 END AS bonus_range,
 COUNT(*) AS count
 FROM(
SELECT CAST(bonus AS DECIMAL(10,2)) AS bonus_clean
FROM raw_payroll
WHERE CAST(bonus AS DECIMAL(10,2)) < 1000) AS b
GROUP BY bonus_range;

-- 1-99(104 rows data entry) set to null

SELECT COUNT(*) FROM raw_payroll
WHERE ABS(CAST(gross_salary AS DECIMAL(10,2))) < CAST(bonus AS DECIMAL(10,2));
-- 2126 bonus more than gross_salary which may be data entry and set to null
 
 
 SELECT COUNT(*) FROM raw_payroll
 WHERE TRIM(tax_deduction) = '' OR tax_deduction IS NULL;
 -- 0 null or blank
SELECT
    MAX(CAST(tax_deduction AS DECIMAL(10,2))) AS MAX_tax_deduction,
    MIN(CAST(tax_deduction AS DECIMAL(10,2))) AS MIN_tax_deduction,
    AVG(CAST(tax_deduction AS DECIMAL(10,2))) AS AVG_tax_deduction
FROM raw_payroll;

SELECT * FROM raw_payroll
WHERE CAST(tax_deduction AS DECIMAL(10,2))<1000;
-- 3 rows 
-- looks right and reasonable

SELECT COUNT(*) FROM raw_payroll
WHERE ABS(CAST(gross_salary AS DECIMAL(10,2))) < CAST(tax_deduction AS DECIMAL(10,2));
-- 0 row
SELECT * FROM raw_payroll ;

-- /////// performance file //////// 

SELECT COUNT(*) FROM raw_performance; 
-- 52700 TOTAL ROWS

SELECT COUNT(DISTINCT employee_id) FROM raw_performance;  
-- 50000 UNIQUE employee id 


SELECT COUNT(*) FROM(
SELECT employee_id,review_year,COUNT(*)
FROM raw_performance
GROUP BY employee_id,review_year
HAVING COUNT(*)>1) AS D;
-- 1729 duplicate based on employee_id,review_year this combination

SELECT
    SUM(CASE WHEN employee_id IS NULL 
        OR employee_id = '' THEN 1 ELSE 0 END) AS emp_nulls,
    SUM(CASE WHEN review_year IS NULL 
        OR review_year = '' THEN 1 ELSE 0 END) AS year_nulls,
    SUM(CASE WHEN performance_rating IS NULL 
        OR performance_rating = '' THEN 1 ELSE 0 END) AS rating_nulls,
    SUM(CASE WHEN promotion_status IS NULL 
        OR promotion_status = '' THEN 1 ELSE 0 END) AS promo_nulls,
    SUM(CASE WHEN training_hours IS NULL 
        OR TRIM(training_hours) = '' THEN 1 ELSE 0 END) AS training_nulls
FROM (
    SELECT 
        TRIM(employee_id) AS employee_id,
        TRIM(review_year) AS review_year,
        TRIM(performance_rating) AS performance_rating,
        TRIM(promotion_status) AS promotion_status,
        TRIM(training_hours) AS training_hours
    FROM raw_performance
) AS nullcheck;
-- 0 null or blank in any field 


SELECT DISTINCT performance_rating, COUNT(*) AS count
FROM raw_performance
GROUP BY performance_rating
ORDER BY performance_rating;
-- Unique performance ratings
-- 1-5 rating


SELECT DISTINCT promotion_status, COUNT(*) AS count
FROM raw_performance
GROUP BY promotion_status
ORDER BY promotion_status;
-- Unique promotion status
-- only two Not Promoted and Promoted

SELECT
    MAX(CAST(training_hours AS DECIMAL(10,2))) AS MAX_training_hours,
    MIN(CAST(training_hours AS DECIMAL(10,2))) AS MIN_training_hours,
    AVG(CAST(training_hours AS DECIMAL(10,2))) AS AVG_training_hours
FROM raw_performance;
-- MAX 120.00
-- MIN 0 
-- AVG 60~

SELECT performance_rating, COUNT(*) FROM raw_performance
WHERE CAST(training_hours AS DECIMAL(10,2)) = 0
GROUP BY performance_rating
ORDER BY performance_rating;
-- keep 0 training_hours as valid


 SELECT * FROM raw_performance ;

