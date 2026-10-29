-- q07_loan_outcome_by_client_and_district.sql
-- Question: Does the loan outcome differ by client (age, gender) and district (salary, unemployment)?
-- Reads:    loan_stg, disp_stg, client_stg, district_stg
-- Note:     each loan is linked to its account's owner (one owner per account) and the owner's district.
--           Age is measured on the loan date. Unemployment uses the 1996 rate (1995 is missing for one district).
--           Groups are small (76 problem loans in total), so differences are indicative, not conclusive.

USE czech_bank;

WITH loan_profile AS (
    SELECT
        loan_stg.loan_id,
        loan_stg.status IN ('finished_unpaid', 'running_in_debt')                  AS problem,
        client_stg.gender,
        TIMESTAMPDIFF(YEAR, client_stg.birth_date, loan_stg.loan_date)             AS age_at_loan,
        district_stg.average_salary,
        district_stg.unemployment_rate_1996
    FROM loan_stg
    JOIN disp_stg     ON disp_stg.account_id = loan_stg.account_id AND disp_stg.role = 'owner'
    JOIN client_stg   ON client_stg.client_id = disp_stg.client_id
    JOIN district_stg ON district_stg.district_id = client_stg.district_id
),
loan_groups AS (
    SELECT
        problem,
        gender,
        CASE
            WHEN age_at_loan < 30 THEN '1. under 30'
            WHEN age_at_loan < 45 THEN '2. 30 to 44'
            WHEN age_at_loan < 60 THEN '3. 45 to 59'
            ELSE                       '4. 60 and over'
        END                                                  AS age_band,
        NTILE(3) OVER (ORDER BY average_salary)              AS salary_third,
        NTILE(3) OVER (ORDER BY unemployment_rate_1996)      AS unemployment_third
    FROM loan_profile
)
SELECT 'gender' AS dimension, gender AS group_name, COUNT(*) AS loans, SUM(problem) AS problem_loans,
       ROUND(SUM(problem) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_groups GROUP BY gender
UNION ALL
SELECT 'age at loan', age_band, COUNT(*), SUM(problem), ROUND(SUM(problem) * 100 / COUNT(*), 1)
FROM loan_groups GROUP BY age_band
UNION ALL
SELECT 'district salary (1 = lowest third)', CAST(salary_third AS CHAR), COUNT(*), SUM(problem),
       ROUND(SUM(problem) * 100 / COUNT(*), 1)
FROM loan_groups GROUP BY salary_third
UNION ALL
SELECT 'district unemployment (1 = lowest third)', CAST(unemployment_third AS CHAR), COUNT(*), SUM(problem),
       ROUND(SUM(problem) * 100 / COUNT(*), 1)
FROM loan_groups GROUP BY unemployment_third
ORDER BY dimension, group_name;
