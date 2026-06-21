-- 1. CREATE TABLE
-- Matches the raw CSV exactly: 16 columns, in this exact order.
-- high_risk_flag is a GENERATED column - Postgres computes it automatically
-- from layoff_risk on every insert, so we don't need Python for this at all.
DROP TABLE IF EXISTS ai_job_risk;

CREATE TABLE ai_job_risk (
    employee_id           SERIAL PRIMARY KEY,
    age                   INT,
    education_level       VARCHAR(20),
    years_experience      INT,
    industry               VARCHAR(30),
    job_role               VARCHAR(40),
    company_size          VARCHAR(10),
    job_level              VARCHAR(10),
    routine_task_pct      INT,
    creativity_requirement INT,
    human_interaction_level INT,
    ai_adoption_level     VARCHAR(10),
    num_ai_tools_used     INT,
    ai_usage_hrs_per_week INT,
    tasks_automated_pct   INT,
    ai_training_hours     INT,
    layoff_risk            VARCHAR(10),
    high_risk_flag        INT GENERATED ALWAYS AS (CASE WHEN layoff_risk = 'High' THEN 1 ELSE 0 END) STORED
);

-- 2. IMPORT DATA
-- Run this from psql. Adjust the path below to wherever you saved the CSV
-- (e.g. 'C:/Users/yourname/Downloads/ai-impact-jobs-layoff-risk-dataset.csv' on Windows,
-- or '/home/yourname/Downloads/ai-impact-jobs-layoff-risk-dataset.csv' on Mac/Linux).
--
-- IMPORTANT: the column list below has exactly 16 columns, matching the raw CSV.
-- employee_id and high_risk_flag are NOT listed here - Postgres fills those in
-- automatically (employee_id via SERIAL, high_risk_flag via the GENERATED expression).

copy ai_job_risk(age, education_level, years_experience, industry, job_role, company_size, job_level, routine_task_pct, creativity_requirement, human_interaction_level, ai_adoption_level, num_ai_tools_used, ai_usage_hrs_per_week, tasks_automated_pct, ai_training_hours, layoff_risk)
FROM 'ai-impact-jobs-layoff-risk-dataset.csv'
DELIMITER ',' CSV HEADER;

-- 3. SANITY CHECK
SELECT COUNT(*) AS total_rows FROM ai_job_risk;
SELECT * FROM ai_job_risk LIMIT 5;
SELECT layoff_risk, high_risk_flag, COUNT(*) FROM ai_job_risk GROUP BY 1, 2 ORDER BY 1;
