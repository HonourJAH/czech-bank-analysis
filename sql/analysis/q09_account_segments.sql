-- q09_account_segments.sql
-- Question: How can accounts be segmented by activity and balance?
-- Reads:    account_stg, trans_stg
-- Method:   activity = transactions per month since the account opened (to 1998-12-31);
--           balance = the account's average recorded balance. Each is split at the median
--           (NTILE(2)), giving four segments.
-- Note:     segment boundaries are an analytical choice.

USE czech_bank;

WITH account_stats AS (
    SELECT
        account_stg.account_id,
        COUNT(trans_stg.trans_id) / GREATEST(TIMESTAMPDIFF(MONTH, account_stg.open_date, '1998-12-31'), 1)
                                                             AS transactions_per_month,
        AVG(trans_stg.balance)                               AS avg_balance,
        SUM(CASE WHEN trans_stg.direction = 'credit' THEN trans_stg.amount ELSE 0 END) AS money_in
    FROM account_stg
    JOIN trans_stg ON trans_stg.account_id = account_stg.account_id
    GROUP BY account_stg.account_id, account_stg.open_date
),
scored_accounts AS (
    SELECT
        *,
        NTILE(2) OVER (ORDER BY transactions_per_month) AS activity_half,
        NTILE(2) OVER (ORDER BY avg_balance)            AS balance_half
    FROM account_stats
)
SELECT
    CASE
        WHEN activity_half = 2 AND balance_half = 2 THEN '1. high activity, high balance'
        WHEN activity_half = 1 AND balance_half = 2 THEN '2. low activity, high balance (savers)'
        WHEN activity_half = 2 AND balance_half = 1 THEN '3. high activity, low balance'
        ELSE                                             '4. low activity, low balance'
    END                                                                  AS segment,
    COUNT(*)                                                             AS accounts,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)                     AS pct_of_accounts,
    ROUND(AVG(avg_balance))                                              AS avg_balance,
    ROUND(AVG(transactions_per_month), 1)                                AS transactions_per_month,
    ROUND(SUM(money_in) * 100 / SUM(SUM(money_in)) OVER (), 1)           AS pct_of_money_in
FROM scored_accounts
GROUP BY segment
ORDER BY segment;
