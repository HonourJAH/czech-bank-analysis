-- q01_size_and_growth.sql
-- Question: How big is the bank in the data, and how did it grow?
-- Reads:    client_stg, disp_stg, account_stg, loan_stg, card_stg, order_stg, trans_stg
-- Note:     no account was opened after 1997-12-29, so 1998 shows no new accounts.

USE czech_bank;

-- Size of the data
SELECT
    (SELECT COUNT(*) FROM client_stg)                         AS clients,
    (SELECT COUNT(*) FROM disp_stg WHERE role = 'owner')      AS owners,
    (SELECT COUNT(*) FROM disp_stg WHERE role = 'authorised_user') AS authorised_users,
    (SELECT COUNT(*) FROM account_stg)                        AS accounts,
    (SELECT COUNT(*) FROM loan_stg)                           AS loans,
    (SELECT COUNT(*) FROM card_stg)                           AS cards,
    (SELECT COUNT(*) FROM order_stg)                          AS standing_orders,
    (SELECT COUNT(*) FROM trans_stg)                          AS transactions;

-- Accounts opened per year, with the running total
SELECT
    YEAR(open_date)                                           AS open_year,
    COUNT(*)                                                  AS accounts_opened,
    SUM(COUNT(*)) OVER (ORDER BY YEAR(open_date))             AS cumulative_accounts
FROM account_stg
GROUP BY YEAR(open_date)
ORDER BY open_year;
