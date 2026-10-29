-- q03_transaction_mix.sql
-- Question: What kinds of transaction make up the activity, by count and by value?
-- Reads:    trans_stg
-- Note:     a blank operation means an automatic interest credit (see docs/decision-log.md).

USE czech_bank;

-- By kind of operation
SELECT
    direction,
    COALESCE(operation, 'interest_credit_no_operation')                          AS kind,
    COUNT(*)                                                                     AS transactions,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)                             AS pct_of_transactions,
    ROUND(SUM(amount))                                                           AS total_value,
    ROUND(SUM(amount) * 100 / SUM(SUM(amount)) OVER (), 1)                       AS pct_of_value,
    ROUND(AVG(amount))                                                           AS average_amount
FROM trans_stg
GROUP BY direction, kind
ORDER BY total_value DESC;

-- By payment purpose (where one was recorded)
SELECT
    direction,
    COALESCE(purpose, 'not_recorded')                                            AS purpose,
    COUNT(*)                                                                     AS transactions,
    ROUND(SUM(amount))                                                           AS total_value
FROM trans_stg
GROUP BY direction, purpose
ORDER BY total_value DESC;
