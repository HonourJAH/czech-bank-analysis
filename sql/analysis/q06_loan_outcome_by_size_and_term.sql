-- q06_loan_outcome_by_size_and_term.sql
-- Question: Does the loan outcome differ by amount and duration?
-- Reads:    loan_stg
-- Note:     only 76 loans are problem loans, so percentages in small groups are noisy.

USE czech_bank;

-- By amount
SELECT
    CASE
        WHEN amount <  50000  THEN '1. under 50,000'
        WHEN amount < 100000  THEN '2. 50,000 to 99,999'
        WHEN amount < 200000  THEN '3. 100,000 to 199,999'
        WHEN amount < 300000  THEN '4. 200,000 to 299,999'
        ELSE                       '5. 300,000 and over'
    END                                                                              AS amount_band,
    COUNT(*)                                                                         AS loans,
    SUM(status IN ('finished_unpaid', 'running_in_debt'))                            AS problem_loans,
    ROUND(SUM(status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_stg
GROUP BY amount_band
ORDER BY amount_band;

-- By duration
SELECT
    duration_months,
    COUNT(*)                                                                         AS loans,
    SUM(status IN ('finished_unpaid', 'running_in_debt'))                            AS problem_loans,
    ROUND(SUM(status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct,
    ROUND(AVG(amount))                                                               AS average_amount
FROM loan_stg
GROUP BY duration_months
ORDER BY duration_months;

-- By year the loan was granted (older loans have had longer to fail)
SELECT
    YEAR(loan_date)                                                                  AS loan_year,
    COUNT(*)                                                                         AS loans,
    SUM(status IN ('finished_paid', 'finished_unpaid'))                              AS finished_loans,
    SUM(status IN ('finished_unpaid', 'running_in_debt'))                            AS problem_loans,
    ROUND(SUM(status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_stg
GROUP BY YEAR(loan_date)
ORDER BY loan_year;
