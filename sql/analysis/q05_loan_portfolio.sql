-- q05_loan_portfolio.sql
-- Question: How large is the loan portfolio, and how many loans ended in trouble?
-- Reads:    loan_stg
-- Note:     problem loans = finished_unpaid or running_in_debt. The loan table has no interest figure
--           (monthly payment = amount / duration), so profit and cost of credit cannot be measured.
--           Running loans (running_ok) may still fail later.

USE czech_bank;

-- Headline
SELECT
    COUNT(*)                                                                         AS loans,
    ROUND(SUM(amount))                                                               AS total_lent,
    ROUND(AVG(amount))                                                               AS average_loan,
    SUM(status IN ('finished_unpaid', 'running_in_debt'))                            AS problem_loans,
    ROUND(SUM(status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct_of_loans,
    ROUND(SUM(CASE WHEN status IN ('finished_unpaid', 'running_in_debt') THEN amount END)) AS problem_amount,
    ROUND(SUM(CASE WHEN status IN ('finished_unpaid', 'running_in_debt') THEN amount END) * 100 / SUM(amount), 1) AS problem_pct_of_amount
FROM loan_stg;

-- By status
SELECT
    status,
    COUNT(*)                                             AS loans,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)     AS pct_of_loans,
    ROUND(SUM(amount))                                   AS total_amount,
    ROUND(SUM(amount) * 100 / SUM(SUM(amount)) OVER (), 1) AS pct_of_amount,
    ROUND(AVG(amount))                                   AS average_amount
FROM loan_stg
GROUP BY status
ORDER BY status;

-- Loans granted per year
SELECT
    YEAR(loan_date)      AS loan_year,
    COUNT(*)             AS loans,
    ROUND(SUM(amount))   AS total_lent
FROM loan_stg
GROUP BY YEAR(loan_date)
ORDER BY loan_year;
