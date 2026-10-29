-- q10_overdrafts_and_loan_trouble.sql
-- Question: Which accounts go overdrawn, and does it relate to loan trouble?
-- Reads:    trans_stg, loan_stg
-- Note:     the second query only counts overdrafts before the loan was granted, so the overdraft
--           cannot be a consequence of the loan trouble. It shows an association, not a cause.

USE czech_bank;

-- Ever overdrawn at any time, against the loan outcome
WITH overdrawn_accounts AS (
    SELECT DISTINCT account_id FROM trans_stg WHERE balance < 0
)
SELECT
    CASE WHEN overdrawn_accounts.account_id IS NULL THEN 'never overdrawn' ELSE 'overdrawn at some point' END AS overdraft_status,
    COUNT(*)                                                                         AS loans,
    SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt'))                   AS problem_loans,
    ROUND(SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_stg
LEFT JOIN overdrawn_accounts ON overdrawn_accounts.account_id = loan_stg.account_id
GROUP BY overdraft_status;

-- Overdrawn before the loan was granted, against the loan outcome
SELECT
    CASE WHEN EXISTS (
             SELECT 1 FROM trans_stg
             WHERE trans_stg.account_id = loan_stg.account_id
               AND trans_stg.balance < 0
               AND trans_stg.trans_date < loan_stg.loan_date
         ) THEN 'overdrawn before the loan' ELSE 'not overdrawn before the loan' END AS status_before_loan,
    COUNT(*)                                                                         AS loans,
    SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt'))                   AS problem_loans,
    ROUND(SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_stg
GROUP BY status_before_loan;


-- The three groups side by side: never overdrawn, first overdrawn after the loan, overdrawn before the loan
SELECT
    CASE
        WHEN EXISTS (
            SELECT 1 FROM trans_stg
            WHERE trans_stg.account_id = loan_stg.account_id
              AND trans_stg.balance < 0
              AND trans_stg.trans_date < loan_stg.loan_date
        ) THEN '3. overdrawn before the loan'
        WHEN EXISTS (
            SELECT 1 FROM trans_stg
            WHERE trans_stg.account_id = loan_stg.account_id
              AND trans_stg.balance < 0
              AND trans_stg.trans_date >= loan_stg.loan_date
        ) THEN '2. overdrawn only after the loan'
        ELSE '1. never overdrawn'
    END                                                                              AS overdraft_timing,
    COUNT(*)                                                                         AS loans,
    SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt'))                   AS problem_loans,
    ROUND(SUM(loan_stg.status IN ('finished_unpaid', 'running_in_debt')) * 100 / COUNT(*), 1) AS problem_pct
FROM loan_stg
GROUP BY overdraft_timing
ORDER BY overdraft_timing;
