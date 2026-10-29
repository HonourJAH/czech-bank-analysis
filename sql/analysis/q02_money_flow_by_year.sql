-- q02_money_flow_by_year.sql
-- Question: How much money moved in and out each year, and what was the net flow?
-- Reads:    trans_stg
-- Note:     money in = credits (including interest credited); money out = debits (including fees and
--           loan payments). Amounts are positive in the data and the direction is held in `direction`.

USE czech_bank;

SELECT
    YEAR(trans_date)                                                  AS year,
    COUNT(*)                                                          AS transactions,
    COUNT(DISTINCT account_id)                                        AS active_accounts,
    ROUND(SUM(CASE WHEN direction = 'credit' THEN amount ELSE 0 END)) AS money_in,
    ROUND(SUM(CASE WHEN direction = 'debit'  THEN amount ELSE 0 END)) AS money_out,
    ROUND(SUM(CASE WHEN direction = 'credit' THEN amount ELSE -amount END)) AS net_flow,
    ROUND(SUM(CASE WHEN direction = 'credit' THEN amount ELSE 0 END) / COUNT(DISTINCT account_id)) AS money_in_per_active_account
FROM trans_stg
GROUP BY YEAR(trans_date)
ORDER BY year;
