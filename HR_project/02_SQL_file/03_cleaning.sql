USE hr_analytics;

-- ///////// CLEANING LAYER ///////


-- cleaning employee table 
-- Create a clean employee view

CREATE VIEW employees_clean AS

-- Step 1: Identify duplicate employee records
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY employee_id
               ORDER BY employee_id
           ) AS rn
    FROM raw_employees
),

-- Step 2: Keep only the first occurrence of each employee
dedup AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
),

-- Step 3: Convert inconsistent date formats into standard SQL DATE format
converted_date AS (
    SELECT *,
    
           -- Clean Joining Date
           CASE
               WHEN TRIM(joining_date) = '' OR joining_date IS NULL THEN NULL
               WHEN REGEXP_LIKE(TRIM(joining_date),'^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
                    THEN STR_TO_DATE(TRIM(joining_date),'%Y-%m-%d')
               WHEN REGEXP_LIKE(TRIM(joining_date),'^[0-9]{2}-[0-9]{2}-[0-9]{4}$')
                    THEN STR_TO_DATE(TRIM(joining_date),'%d-%m-%Y')
               ELSE NULL
           END AS joining_date_clean,

           -- Clean Exit Date
           CASE
               WHEN TRIM(exit_date) = '' OR exit_date IS NULL THEN NULL
               WHEN REGEXP_LIKE(TRIM(exit_date),'^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
                    THEN STR_TO_DATE(TRIM(exit_date),'%Y-%m-%d')
               WHEN REGEXP_LIKE(TRIM(exit_date),'^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
                    THEN STR_TO_DATE(TRIM(exit_date),'%d/%m/%Y')
               ELSE NULL
           END AS exit_date_clean

    FROM dedup
)

-- Step 4: Final data cleaning and standardization
SELECT

    -- Remove blanks
    NULLIF(TRIM(employee_id), '') AS employee_id,
    NULLIF(TRIM(employee_name), '') AS employee_name,
    NULLIF(TRIM(gender), '') AS gender,

    -- Standardize department names
    CASE
        WHEN TRIM(department) = '' OR department IS NULL THEN NULL
        WHEN LOWER(TRIM(department)) = 'finance'
            THEN 'Finance'
        WHEN LOWER(TRIM(department)) IN ('hr','human resources')
            THEN 'Human Resources'
        WHEN LOWER(TRIM(department)) IN ('it','information technology')
            THEN 'Information Technology'
        WHEN LOWER(TRIM(department)) = 'marketing'
            THEN 'Marketing'
        WHEN LOWER(TRIM(department)) = 'operations'
            THEN 'Operations'
        WHEN LOWER(TRIM(department)) = 'sales'
            THEN 'Sales'
        ELSE 'Unknown'
    END AS department,

    NULLIF(TRIM(job_role), '') AS job_role,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(manager_id), '') AS manager_id,

    joining_date_clean AS joining_date,

    NULLIF(TRIM(employee_status), '') AS employee_status,

    -- Remove invalid exit dates for active employees
    CASE
        WHEN employee_status = 'Active'
             AND exit_date_clean = '2025-01-10'
        THEN NULL
        ELSE exit_date_clean
    END AS exit_date,

    -- Clean salary values
    CASE
        WHEN TRIM(monthly_salary) = ''
             OR CAST(monthly_salary AS DECIMAL(10,2)) = 0
        THEN NULL
        ELSE ABS(CAST(monthly_salary AS DECIMAL(10,2)))
    END AS monthly_salary

FROM converted_date;


-- cleaning attendacne file
-- Create a clean attendance view

CREATE VIEW attendance_clean AS

-- Step 1: Identify duplicate attendance records
WITH ranked AS (
    SELECT
        employee_id,
        attendance_date,
        attendance_percent,
        work_mode,

        ROW_NUMBER() OVER (
            PARTITION BY employee_id, attendance_date
            ORDER BY CAST(
                REPLACE(TRIM(attendance_percent), '%', '')
                AS DECIMAL(5,2)
            )
        ) AS rn

    FROM raw_attendance
),

-- Step 2: Keep only one record per employee per date
dedup AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
)

-- Step 3: Clean and standardize data
SELECT

    -- Remove blank employee IDs
    NULLIF(TRIM(employee_id), '') AS employee_id,

    -- Standardize attendance date format
    CASE
        WHEN TRIM(attendance_date) = ''
             OR attendance_date IS NULL
        THEN NULL

        WHEN REGEXP_LIKE(
             TRIM(attendance_date),
             '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
             )
        THEN STR_TO_DATE(
             TRIM(attendance_date),
             '%Y-%m-%d'
             )

        WHEN REGEXP_LIKE(
             TRIM(attendance_date),
             '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
             )
        THEN STR_TO_DATE(
             TRIM(attendance_date),
             '%d-%m-%Y'
             )

        WHEN REGEXP_LIKE(
             TRIM(attendance_date),
             '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
             )
        THEN STR_TO_DATE(
             TRIM(attendance_date),
             '%d/%m/%Y'
             )

        ELSE NULL
    END AS attendance_date,

    -- Validate attendance percentage
    CASE
        WHEN TRIM(attendance_percent) = ''
             OR attendance_percent IS NULL
        THEN NULL

        WHEN CAST(TRIM(attendance_percent) AS DECIMAL(6,2)) < 0
        THEN NULL

        WHEN CAST(TRIM(attendance_percent) AS DECIMAL(6,2)) > 100
        THEN NULL

        ELSE CAST(TRIM(attendance_percent) AS DECIMAL(6,2))
    END AS attendance_percent,

    -- Standardize work mode values
    CASE
        WHEN LOWER(TRIM(work_mode))
             IN ('hybrid','office','wfh')
        THEN TRIM(work_mode)

        ELSE NULL
    END AS work_mode

FROM dedup;

-- cleaning payroll file
-- Create a clean payroll view

CREATE VIEW payroll_clean AS

-- Step 1: Identify duplicate payroll records
WITH ranked AS (
    SELECT
        employee_id,
        salary_month,
        gross_salary,
        bonus,
        tax_deduction,

        ROW_NUMBER() OVER (
            PARTITION BY employee_id, salary_month
            ORDER BY ABS(
                CAST(TRIM(bonus) AS DECIMAL(10,2))
            ) DESC
        ) AS rn

    FROM raw_payroll
),

-- Step 2: Keep only one payroll record per employee per month per employee
dedup AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
)

-- Step 3: Clean and validate payroll data
SELECT

    -- Remove blank employee IDs
    NULLIF(TRIM(employee_id), '') AS employee_id,

    -- Convert salary month into a valid date (first day of month)
    CASE
        WHEN TRIM(salary_month) = ''
             OR salary_month IS NULL
        THEN NULL

        WHEN NOT REGEXP_LIKE(
             TRIM(salary_month),
             '^[0-9]{4}-[0-9]{2}$'
             )
        THEN NULL

        WHEN REGEXP_LIKE(
             TRIM(salary_month),
             '^[0-9]{4}-[0-9]{2}$'
             )
             AND SUBSTR(TRIM(salary_month),6,2)+0
                 BETWEEN 1 AND 12
        THEN STR_TO_DATE(
             CONCAT(salary_month,'-01'),
             '%Y-%m-%d'
             )

        ELSE NULL
    END AS salary_month,

    -- Convert salary to positive numeric value
    ABS(
        CAST(
            NULLIF(TRIM(gross_salary),'')
            AS DECIMAL(10,2)
        )
    ) AS gross_salary,

    -- Validate bonus values
    CASE
        WHEN TRIM(bonus) = ''
             OR bonus IS NULL
        THEN NULL

        -- Remove negative bonus
        WHEN CAST(TRIM(bonus) AS DECIMAL(10,2)) < 0
        THEN NULL

        -- Remove unrealistic bonus values
        WHEN CAST(TRIM(bonus) AS DECIMAL(10,2))
             BETWEEN 1 AND 99
        THEN NULL

        -- Bonus should not exceed salary
        WHEN ABS(CAST(TRIM(gross_salary) AS DECIMAL(10,2)))
             < CAST(TRIM(bonus) AS DECIMAL(10,2))
        THEN NULL

        ELSE CAST(TRIM(bonus) AS DECIMAL(10,2))
    END AS bonus,

    -- Convert tax deduction to numeric
    CASE
        WHEN TRIM(tax_deduction) = ''
             OR tax_deduction IS NULL
        THEN NULL

        ELSE CAST(TRIM(tax_deduction) AS DECIMAL(10,2))
    END AS tax_deduction

FROM dedup;

-- cleaning performance table
-- Create a clean performance view
CREATE VIEW performance_clean AS

-- Step 1: Identify duplicate performance records
WITH ranked AS (
    SELECT
        employee_id,
        review_year,
        performance_rating,
        promotion_status,
        training_hours,

        ROW_NUMBER() OVER (
            PARTITION BY employee_id, review_year
            ORDER BY CAST(TRIM(performance_rating) AS UNSIGNED) DESC
        ) AS rn

    FROM raw_performance
),

-- Step 2: Keep only the highest-rated record per employee per year
dedup AS (
    SELECT *
    FROM ranked
    WHERE rn = 1
)

-- Step 3: Clean and standardize performance data
SELECT

    -- Remove blank employee IDs
    NULLIF(TRIM(employee_id), '') AS employee_id,

    -- Convert review year to numeric
    NULLIF(
        CAST(TRIM(review_year) AS UNSIGNED),
        ''
    ) AS review_year,

    -- Convert performance rating to numeric
    NULLIF(
        CAST(TRIM(performance_rating) AS UNSIGNED),
        ''
    ) AS performance_rating,

    -- Standardize promotion status
    CASE
        WHEN TRIM(promotion_status) = ''
             OR promotion_status IS NULL
        THEN NULL

        WHEN TRIM(promotion_status)
             IN ('Promoted', 'Not Promoted')
        THEN TRIM(promotion_status)

        ELSE NULL
    END AS promotion_status,

    -- Convert training hours to numeric
    CAST(
        TRIM(training_hours)
        AS DECIMAL(6,2)
    ) AS training_hours

FROM dedup;