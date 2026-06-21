-- Q1. Overall high-risk rate (basic aggregation)
SELECT
    COUNT(*) AS total_employees,
    SUM(high_risk_flag) AS high_risk_count,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk;
select * FROM ai_job_risk;

-- Q2. High-risk rate by industry, ranked highest to lowest
SELECT
    industry,
    COUNT(*) AS total_employees,
    SUM(high_risk_flag) AS high_risk_count,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY industry
ORDER BY high_risk_pct DESC;


-- Q3. High-risk rate by job role within each industry (top 3 riskiest roles per industry)
-- Uses window function RANK() partitioned by industry
WITH role_risk AS (
    SELECT
        industry,
        job_role,
        COUNT(*) AS total_employees,
        ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
    FROM ai_job_risk
    GROUP BY industry, job_role
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY industry ORDER BY high_risk_pct DESC) AS risk_rank
    FROM role_risk
)
SELECT industry, job_role, total_employees, high_risk_pct, risk_rank
FROM ranked
WHERE risk_rank <= 3
ORDER BY industry, risk_rank;


-- Q4. AI adoption level vs high-risk rate (does more AI adoption correlate with risk?)
SELECT
    ai_adoption_level,
    COUNT(*) AS total_employees,
    ROUND(AVG(tasks_automated_pct), 2) AS avg_tasks_automated_pct,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY ai_adoption_level
ORDER BY high_risk_pct DESC;


-- Q5. Risk tier segmentation using CTE + CASE (routine task percentage buckets)
WITH task_buckets AS (
    SELECT
        *,
        CASE
            WHEN routine_task_pct < 33 THEN 'Low Routine (0-33%)'
            WHEN routine_task_pct < 67 THEN 'Medium Routine (34-66%)'
            ELSE 'High Routine (67-100%)'
        END AS routine_bucket
    FROM ai_job_risk
)
SELECT
    routine_bucket,
    COUNT(*) AS total_employees,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM task_buckets
GROUP BY routine_bucket
ORDER BY high_risk_pct DESC;


-- Q6. Job level vs risk, with company size breakdown
SELECT
    job_level,
    company_size,
    COUNT(*) AS total_employees,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY job_level, company_size
ORDER BY job_level, high_risk_pct DESC;


-- Q7. Education level vs average AI training hours and risk
SELECT
    education_level,
    COUNT(*) AS total_employees,
    ROUND(AVG(ai_training_hours), 2) AS avg_training_hours,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY education_level
ORDER BY high_risk_pct DESC;


-- Q8. Top 10 highest-risk job roles overall (min 100 employees to avoid noise from small groups)
SELECT
    job_role,
    COUNT(*) AS total_employees,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY job_role
HAVING COUNT(*) >= 100
ORDER BY high_risk_pct DESC
LIMIT 10;


-- Q9. Running cumulative average of tasks automated, ordered by routine task percentage
-- Demonstrates window function with frame clause
SELECT
    employee_id,
    routine_task_pct,
    tasks_automated_pct,
    ROUND(AVG(tasks_automated_pct) OVER (
        ORDER BY routine_task_pct
        ROWS BETWEEN 500 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_avg_automation
FROM ai_job_risk
ORDER BY routine_task_pct
LIMIT 20;


-- Q10. Percentile ranking of employees by tasks automated percentage (NTILE)
WITH percentile_data AS (
    SELECT
        employee_id,
        job_role,
        tasks_automated_pct,
        high_risk_flag,
        NTILE(4) OVER (ORDER BY tasks_automated_pct) AS automation_quartile
    FROM ai_job_risk
)
SELECT
    automation_quartile,
    COUNT(*) AS total_employees,
    ROUND(MIN(tasks_automated_pct), 0) AS min_pct,
    ROUND(MAX(tasks_automated_pct), 0) AS max_pct,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM percentile_data
GROUP BY automation_quartile
ORDER BY automation_quartile;


-- Q11. Difference from industry average risk rate for each job role (window function)
WITH role_industry_risk AS (
    SELECT
        industry,
        job_role,
        COUNT(*) AS total_employees,
        ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS role_risk_pct
    FROM ai_job_risk
    GROUP BY industry, job_role
)
SELECT
    industry,
    job_role,
    total_employees,
    role_risk_pct,
    ROUND(AVG(role_risk_pct) OVER (PARTITION BY industry), 2) AS industry_avg_risk_pct,
    ROUND(role_risk_pct - AVG(role_risk_pct) OVER (PARTITION BY industry), 2) AS diff_from_industry_avg
FROM role_industry_risk
ORDER BY industry, diff_from_industry_avg DESC;


-- Q12. Years of experience bands vs risk (does seniority protect against risk?)
WITH experience_bands AS (
    SELECT
        *,
        CASE
            WHEN years_experience <= 3 THEN '0-3 yrs'
            WHEN years_experience <= 7 THEN '4-7 yrs'
            WHEN years_experience <= 12 THEN '8-12 yrs'
            ELSE '13+ yrs'
        END AS experience_band
    FROM ai_job_risk
)
SELECT
    experience_band,
    COUNT(*) AS total_employees,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM experience_bands
GROUP BY experience_band
ORDER BY
    CASE experience_band
        WHEN '0-3 yrs' THEN 1
        WHEN '4-7 yrs' THEN 2
        WHEN '8-12 yrs' THEN 3
        ELSE 4
    END;


-- Q13. Number of AI tools used vs average risk (does more tool exposure increase or reduce risk?)
SELECT
    num_ai_tools_used,
    COUNT(*) AS total_employees,
    ROUND(AVG(ai_usage_hrs_per_week), 2) AS avg_weekly_ai_hours,
    ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
FROM ai_job_risk
GROUP BY num_ai_tools_used
ORDER BY num_ai_tools_used;


-- Q14. Comprehensive risk profile summary by industry (combines multiple metrics, CTE)
-- Useful as a direct feed into Power BI as a pre-aggregated table
WITH industry_summary AS (
    SELECT
        industry,
        COUNT(*) AS total_employees,
        ROUND(AVG(routine_task_pct), 2) AS avg_routine_task_pct,
        ROUND(AVG(creativity_requirement), 2) AS avg_creativity_requirement,
        ROUND(AVG(tasks_automated_pct), 2) AS avg_tasks_automated_pct,
        ROUND(AVG(ai_training_hours), 2) AS avg_training_hours,
        SUM(high_risk_flag) AS high_risk_count,
        ROUND(100.0 * SUM(high_risk_flag) / COUNT(*), 2) AS high_risk_pct
    FROM ai_job_risk
    GROUP BY industry
)
SELECT *
FROM industry_summary
ORDER BY high_risk_pct DESC;
