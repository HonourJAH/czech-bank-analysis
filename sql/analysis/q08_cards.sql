-- q08_cards.sql
-- Question: How many cards were issued, of which types, and do card holders behave differently?
-- Reads:    card_stg, disp_stg, account_stg, trans_stg
-- Note:     a card belongs to a disposition, which links a client to an account. Differences between
--           card holders and other accounts are associations, not proof that the card caused them.

USE czech_bank;

-- Cards by type
SELECT
    card_type,
    COUNT(*)                                             AS cards,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)     AS pct_of_cards
FROM card_stg
GROUP BY card_type
ORDER BY cards DESC;

-- Cards issued per year
SELECT
    YEAR(issued_date)  AS issue_year,
    COUNT(*)           AS cards_issued
FROM card_stg
GROUP BY YEAR(issued_date)
ORDER BY issue_year;

-- Accounts with and without a card
WITH card_accounts AS (
    SELECT DISTINCT disp_stg.account_id
    FROM card_stg
    JOIN disp_stg ON disp_stg.disp_id = card_stg.disp_id
),
account_activity AS (
    SELECT
        account_id,
        COUNT(*)                                                       AS transactions,
        SUM(CASE WHEN direction = 'debit' THEN amount ELSE 0 END)      AS money_out,
        AVG(balance)                                                   AS avg_balance
    FROM trans_stg
    GROUP BY account_id
)
SELECT
    CASE WHEN card_accounts.account_id IS NULL THEN 'no card' ELSE 'has a card' END AS card_status,
    COUNT(*)                                       AS accounts,
    ROUND(AVG(account_activity.transactions))      AS avg_transactions,
    ROUND(AVG(account_activity.money_out))         AS avg_money_out,
    ROUND(AVG(account_activity.avg_balance))       AS avg_balance
FROM account_stg
LEFT JOIN card_accounts   ON card_accounts.account_id = account_stg.account_id
JOIN account_activity     ON account_activity.account_id = account_stg.account_id
GROUP BY card_status;
