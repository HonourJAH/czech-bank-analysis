-- 02_profile_raw.sql
-- Purpose: measure keys, completeness, validity and consistency of the raw tables before any cleaning.
--          Each check lists the result it produced; the decision it led to is in docs/decision-log.md.
-- Reads:   the *_raw tables in czech_bank
-- Note:    the queries that scan trans_raw (about 1.06 million rows) take a few seconds to a minute.

USE czech_bank;

-- 1. Row counts
-- Expected: account 4,500 | card 892 | client 5,369 | disp 5,369 | district 77 | loan 682 | order 6,471 | trans 1,056,320
SELECT 'account_raw' AS table_name, COUNT(*) AS row_count FROM account_raw
UNION ALL SELECT 'card_raw',     COUNT(*) FROM card_raw
UNION ALL SELECT 'client_raw',   COUNT(*) FROM client_raw
UNION ALL SELECT 'disp_raw',     COUNT(*) FROM disp_raw
UNION ALL SELECT 'district_raw', COUNT(*) FROM district_raw
UNION ALL SELECT 'loan_raw',     COUNT(*) FROM loan_raw
UNION ALL SELECT 'order_raw',    COUNT(*) FROM order_raw
UNION ALL SELECT 'trans_raw',    COUNT(*) FROM trans_raw;

-- 2. Are the IDs unique?
-- Expected: repeated_rows = 0 on every line
SELECT 'account_raw' AS table_name, 'account_id' AS id_column,
       COUNT(*) AS total_rows, COUNT(DISTINCT account_id) AS distinct_ids,
       COUNT(*) - COUNT(DISTINCT account_id) AS repeated_rows
FROM account_raw
UNION ALL SELECT 'card_raw',     'card_id',   COUNT(*), COUNT(DISTINCT card_id),   COUNT(*) - COUNT(DISTINCT card_id)   FROM card_raw
UNION ALL SELECT 'client_raw',   'client_id', COUNT(*), COUNT(DISTINCT client_id), COUNT(*) - COUNT(DISTINCT client_id) FROM client_raw
UNION ALL SELECT 'disp_raw',     'disp_id',   COUNT(*), COUNT(DISTINCT disp_id),   COUNT(*) - COUNT(DISTINCT disp_id)   FROM disp_raw
UNION ALL SELECT 'district_raw', 'A1',        COUNT(*), COUNT(DISTINCT A1),        COUNT(*) - COUNT(DISTINCT A1)        FROM district_raw
UNION ALL SELECT 'loan_raw',     'loan_id',   COUNT(*), COUNT(DISTINCT loan_id),   COUNT(*) - COUNT(DISTINCT loan_id)   FROM loan_raw
UNION ALL SELECT 'order_raw',    'order_id',  COUNT(*), COUNT(DISTINCT order_id),  COUNT(*) - COUNT(DISTINCT order_id)  FROM order_raw
UNION ALL SELECT 'trans_raw',    'trans_id',  COUNT(*), COUNT(DISTINCT trans_id),  COUNT(*) - COUNT(DISTINCT trans_id)  FROM trans_raw;

-- 3. Blank values in trans_raw
-- Expected: blanks only in operation 183,114 | k_symbol 535,314 | bank 782,812 | account 760,931
SELECT
    COUNT(*)                                               AS total_rows,
    SUM(trans_id   IS NULL OR TRIM(trans_id)   = '')       AS blank_trans_id,
    SUM(account_id IS NULL OR TRIM(account_id) = '')       AS blank_account_id,
    SUM(`date`     IS NULL OR TRIM(`date`)     = '')       AS blank_date,
    SUM(`type`     IS NULL OR TRIM(`type`)     = '')       AS blank_type,
    SUM(operation  IS NULL OR TRIM(operation)  = '')       AS blank_operation,
    SUM(amount     IS NULL OR TRIM(amount)     = '')       AS blank_amount,
    SUM(balance    IS NULL OR TRIM(balance)    = '')       AS blank_balance,
    SUM(k_symbol   IS NULL OR TRIM(k_symbol)   = '')       AS blank_k_symbol,
    SUM(bank       IS NULL OR TRIM(bank)       = '')       AS blank_bank,
    SUM(account    IS NULL OR TRIM(account)    = '')       AS blank_account
FROM trans_raw;

-- 3a. What kind of transaction has a blank operation?
-- Expected: one row, PRIJEM with UROK (interest credited), 183,114 rows
SELECT `type`, k_symbol, COUNT(*) AS rows_with_blank_operation
FROM trans_raw
WHERE TRIM(operation) = ''
GROUP BY `type`, k_symbol
ORDER BY rows_with_blank_operation DESC;

-- 3b. Do the blank bank, account and k_symbol follow a rule by transaction kind?
-- Expected: rows_in_group totals 1,056,320; account_but_no_bank totals 21,881 (all withdrawals); bank_but_no_account is 0
SELECT
    `type`,
    operation,
    COUNT(*)                                          AS rows_in_group,
    SUM(TRIM(k_symbol) = '')                          AS k_symbol_blank,
    SUM(TRIM(bank) = '')                              AS bank_blank,
    SUM(TRIM(account) = '')                           AS account_blank,
    SUM(TRIM(bank) = '' AND TRIM(account) <> '')      AS account_but_no_bank,
    SUM(TRIM(bank) <> '' AND TRIM(account) = '')      AS bank_but_no_account
FROM trans_raw
GROUP BY `type`, operation
ORDER BY rows_in_group DESC;

-- 4. Blank values in the other seven tables
-- Expected: 0 everywhere except order_raw.k_symbol (1,379 blanks)
SELECT 'account_raw' AS table_name, 'account_id' AS column_name, COUNT(*) AS total_rows, SUM(TRIM(account_id) = '') AS blanks FROM account_raw
UNION ALL SELECT 'account_raw', 'district_id', COUNT(*), SUM(TRIM(district_id) = '') FROM account_raw
UNION ALL SELECT 'account_raw', 'frequency',   COUNT(*), SUM(TRIM(frequency) = '')   FROM account_raw
UNION ALL SELECT 'account_raw', 'date',        COUNT(*), SUM(TRIM(`date`) = '')      FROM account_raw
UNION ALL SELECT 'card_raw', 'card_id', COUNT(*), SUM(TRIM(card_id) = '') FROM card_raw
UNION ALL SELECT 'card_raw', 'disp_id', COUNT(*), SUM(TRIM(disp_id) = '') FROM card_raw
UNION ALL SELECT 'card_raw', 'type',    COUNT(*), SUM(TRIM(`type`) = '')  FROM card_raw
UNION ALL SELECT 'card_raw', 'issued',  COUNT(*), SUM(TRIM(issued) = '')  FROM card_raw
UNION ALL SELECT 'client_raw', 'client_id',    COUNT(*), SUM(TRIM(client_id) = '')    FROM client_raw
UNION ALL SELECT 'client_raw', 'birth_number', COUNT(*), SUM(TRIM(birth_number) = '') FROM client_raw
UNION ALL SELECT 'client_raw', 'district_id',  COUNT(*), SUM(TRIM(district_id) = '')  FROM client_raw
UNION ALL SELECT 'disp_raw', 'disp_id',    COUNT(*), SUM(TRIM(disp_id) = '')    FROM disp_raw
UNION ALL SELECT 'disp_raw', 'client_id',  COUNT(*), SUM(TRIM(client_id) = '')  FROM disp_raw
UNION ALL SELECT 'disp_raw', 'account_id', COUNT(*), SUM(TRIM(account_id) = '') FROM disp_raw
UNION ALL SELECT 'disp_raw', 'type',       COUNT(*), SUM(TRIM(`type`) = '')     FROM disp_raw
UNION ALL SELECT 'loan_raw', 'loan_id',    COUNT(*), SUM(TRIM(loan_id) = '')    FROM loan_raw
UNION ALL SELECT 'loan_raw', 'account_id', COUNT(*), SUM(TRIM(account_id) = '') FROM loan_raw
UNION ALL SELECT 'loan_raw', 'date',       COUNT(*), SUM(TRIM(`date`) = '')     FROM loan_raw
UNION ALL SELECT 'loan_raw', 'amount',     COUNT(*), SUM(TRIM(amount) = '')     FROM loan_raw
UNION ALL SELECT 'loan_raw', 'duration',   COUNT(*), SUM(TRIM(duration) = '')   FROM loan_raw
UNION ALL SELECT 'loan_raw', 'payments',   COUNT(*), SUM(TRIM(payments) = '')   FROM loan_raw
UNION ALL SELECT 'loan_raw', 'status',     COUNT(*), SUM(TRIM(status) = '')     FROM loan_raw
UNION ALL SELECT 'order_raw', 'order_id',   COUNT(*), SUM(TRIM(order_id) = '')   FROM order_raw
UNION ALL SELECT 'order_raw', 'account_id', COUNT(*), SUM(TRIM(account_id) = '') FROM order_raw
UNION ALL SELECT 'order_raw', 'bank_to',    COUNT(*), SUM(TRIM(bank_to) = '')    FROM order_raw
UNION ALL SELECT 'order_raw', 'account_to', COUNT(*), SUM(TRIM(account_to) = '') FROM order_raw
UNION ALL SELECT 'order_raw', 'amount',     COUNT(*), SUM(TRIM(amount) = '')     FROM order_raw
UNION ALL SELECT 'order_raw', 'k_symbol',   COUNT(*), SUM(TRIM(k_symbol) = '')   FROM order_raw
UNION ALL SELECT 'district_raw', 'A1',  COUNT(*), SUM(TRIM(A1) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A2',  COUNT(*), SUM(TRIM(A2) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A3',  COUNT(*), SUM(TRIM(A3) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A4',  COUNT(*), SUM(TRIM(A4) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A5',  COUNT(*), SUM(TRIM(A5) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A6',  COUNT(*), SUM(TRIM(A6) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A7',  COUNT(*), SUM(TRIM(A7) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A8',  COUNT(*), SUM(TRIM(A8) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A9',  COUNT(*), SUM(TRIM(A9) = '')  FROM district_raw
UNION ALL SELECT 'district_raw', 'A10', COUNT(*), SUM(TRIM(A10) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A11', COUNT(*), SUM(TRIM(A11) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A12', COUNT(*), SUM(TRIM(A12) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A13', COUNT(*), SUM(TRIM(A13) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A14', COUNT(*), SUM(TRIM(A14) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A15', COUNT(*), SUM(TRIM(A15) = '') FROM district_raw
UNION ALL SELECT 'district_raw', 'A16', COUNT(*), SUM(TRIM(A16) = '') FROM district_raw;

-- 5. Placeholders in the numeric district columns
-- Expected: one row, district 69 (Jesenik), with '?' in A12 and A15
SELECT A1, A2, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16
FROM district_raw
WHERE A4  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A5  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A6  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A7  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A8  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A9  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A10 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A11 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A12 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A13 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A14 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A15 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
   OR A16 NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

-- 6. Do all references resolve (orphans)?
-- Expected: orphans = 0 on every line
SELECT 'account.district_id -> district' AS relationship, COUNT(*) AS child_rows, SUM(parent.A1 IS NULL) AS orphans
FROM account_raw AS child LEFT JOIN district_raw AS parent ON child.district_id = parent.A1
UNION ALL
SELECT 'client.district_id -> district', COUNT(*), SUM(parent.A1 IS NULL)
FROM client_raw AS child LEFT JOIN district_raw AS parent ON child.district_id = parent.A1
UNION ALL
SELECT 'disp.client_id -> client', COUNT(*), SUM(parent.client_id IS NULL)
FROM disp_raw AS child LEFT JOIN client_raw AS parent ON child.client_id = parent.client_id
UNION ALL
SELECT 'disp.account_id -> account', COUNT(*), SUM(parent.account_id IS NULL)
FROM disp_raw AS child LEFT JOIN account_raw AS parent ON child.account_id = parent.account_id
UNION ALL
SELECT 'card.disp_id -> disp', COUNT(*), SUM(parent.disp_id IS NULL)
FROM card_raw AS child LEFT JOIN disp_raw AS parent ON child.disp_id = parent.disp_id
UNION ALL
SELECT 'loan.account_id -> account', COUNT(*), SUM(parent.account_id IS NULL)
FROM loan_raw AS child LEFT JOIN account_raw AS parent ON child.account_id = parent.account_id
UNION ALL
SELECT 'order.account_id -> account', COUNT(*), SUM(parent.account_id IS NULL)
FROM order_raw AS child LEFT JOIN account_raw AS parent ON child.account_id = parent.account_id
UNION ALL
SELECT 'trans.account_id -> account', COUNT(*), SUM(parent.account_id IS NULL)
FROM trans_raw AS child LEFT JOIN account_raw AS parent ON child.account_id = parent.account_id;

-- 7. Are the numeric columns plain numbers?
-- Expected: not_a_number = 0 on every line
SELECT 'trans_raw' AS table_name, 'amount' AS column_name, COUNT(*) AS total_rows,
       SUM(amount NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') AS not_a_number FROM trans_raw
UNION ALL SELECT 'trans_raw', 'balance',  COUNT(*), SUM(balance  NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') FROM trans_raw
UNION ALL SELECT 'loan_raw',  'amount',   COUNT(*), SUM(amount   NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') FROM loan_raw
UNION ALL SELECT 'loan_raw',  'duration', COUNT(*), SUM(duration NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') FROM loan_raw
UNION ALL SELECT 'loan_raw',  'payments', COUNT(*), SUM(payments NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') FROM loan_raw
UNION ALL SELECT 'order_raw', 'amount',   COUNT(*), SUM(amount   NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$') FROM order_raw;

-- 8. Dates: format, validity and range (YYMMDD text; 93 to 98 read as 1993 to 1998)
-- Expected: wrong_format and unparseable 0; ranges inside 1993 to 1998
SELECT 'account_raw' AS table_name, 'date' AS column_name, COUNT(*) AS total_rows,
       SUM(`date` NOT REGEXP '^[0-9]{6}$')                AS wrong_format,
       SUM(STR_TO_DATE(`date`, '%y%m%d') IS NULL)         AS unparseable,
       MIN(STR_TO_DATE(`date`, '%y%m%d'))                 AS earliest,
       MAX(STR_TO_DATE(`date`, '%y%m%d'))                 AS latest
FROM account_raw
UNION ALL
SELECT 'loan_raw', 'date', COUNT(*),
       SUM(`date` NOT REGEXP '^[0-9]{6}$'),
       SUM(STR_TO_DATE(`date`, '%y%m%d') IS NULL),
       MIN(STR_TO_DATE(`date`, '%y%m%d')),
       MAX(STR_TO_DATE(`date`, '%y%m%d'))
FROM loan_raw
UNION ALL
SELECT 'trans_raw', 'date', COUNT(*),
       SUM(`date` NOT REGEXP '^[0-9]{6}$'),
       SUM(STR_TO_DATE(`date`, '%y%m%d') IS NULL),
       MIN(STR_TO_DATE(`date`, '%y%m%d')),
       MAX(STR_TO_DATE(`date`, '%y%m%d'))
FROM trans_raw
UNION ALL
SELECT 'card_raw', 'issued', COUNT(*),
       SUM(issued NOT REGEXP '^[0-9]{6} 00:00:00$'),
       SUM(STR_TO_DATE(LEFT(issued, 6), '%y%m%d') IS NULL),
       MIN(STR_TO_DATE(LEFT(issued, 6), '%y%m%d')),
       MAX(STR_TO_DATE(LEFT(issued, 6), '%y%m%d'))
FROM card_raw;

-- 9. Date sequence: nothing dated before its account was opened
-- Expected: violations = 0 on every line
SELECT 'transactions dated before their account was opened' AS check_name, COUNT(*) AS violations
FROM trans_raw AS transactions
JOIN account_raw AS accounts ON transactions.account_id = accounts.account_id
WHERE STR_TO_DATE(transactions.`date`, '%y%m%d') < STR_TO_DATE(accounts.`date`, '%y%m%d')
UNION ALL
SELECT 'loans dated before their account was opened', COUNT(*)
FROM loan_raw AS loans
JOIN account_raw AS accounts ON loans.account_id = accounts.account_id
WHERE STR_TO_DATE(loans.`date`, '%y%m%d') < STR_TO_DATE(accounts.`date`, '%y%m%d')
UNION ALL
SELECT 'cards issued before their account was opened', COUNT(*)
FROM card_raw AS cards
JOIN disp_raw AS dispositions ON cards.disp_id = dispositions.disp_id
JOIN account_raw AS accounts  ON dispositions.account_id = accounts.account_id
WHERE STR_TO_DATE(LEFT(cards.issued, 6), '%y%m%d') < STR_TO_DATE(accounts.`date`, '%y%m%d');

-- 10. Inventory of coded values
-- Expected: short clean lists; each column's counts add up to its table's row count
SELECT 'account.frequency' AS column_name, frequency AS value, COUNT(*) AS n FROM account_raw GROUP BY frequency
UNION ALL SELECT 'card.type',        `type`,     COUNT(*) FROM card_raw  GROUP BY `type`
UNION ALL SELECT 'disp.type',        `type`,     COUNT(*) FROM disp_raw  GROUP BY `type`
UNION ALL SELECT 'loan.status',      status,     COUNT(*) FROM loan_raw  GROUP BY status
UNION ALL SELECT 'order.k_symbol',   k_symbol,   COUNT(*) FROM order_raw GROUP BY k_symbol
UNION ALL SELECT 'trans.type',       `type`,     COUNT(*) FROM trans_raw GROUP BY `type`
UNION ALL SELECT 'trans.operation',  operation,  COUNT(*) FROM trans_raw GROUP BY operation
UNION ALL SELECT 'trans.k_symbol',   k_symbol,   COUNT(*) FROM trans_raw GROUP BY k_symbol
ORDER BY column_name, n DESC;

-- 10a. The two forms of "no k_symbol": an empty string and a single space
-- Expected: single space only for transfers out (52,817) and cash withdrawals (616); both forms span 1993 to 1998
SELECT
    operation,
    CASE
        WHEN LENGTH(k_symbol) = 0 THEN 'empty'
        WHEN LENGTH(k_symbol) = 1 AND k_symbol = ' ' THEN 'single space'
        ELSE 'has a value'
    END AS k_symbol_form,
    COUNT(*) AS n_rows
FROM trans_raw
GROUP BY operation, k_symbol_form
ORDER BY operation, k_symbol_form;

SELECT
    operation,
    CASE WHEN LENGTH(k_symbol) = 0 THEN 'empty' ELSE 'single space' END AS k_symbol_form,
    COUNT(*)                                  AS n_rows,
    MIN(STR_TO_DATE(`date`, '%y%m%d'))        AS first_date,
    MAX(STR_TO_DATE(`date`, '%y%m%d'))        AS last_date
FROM trans_raw
WHERE operation IN ('PREVOD NA UCET', 'VYBER')
  AND LENGTH(k_symbol) <= 1
GROUP BY operation, k_symbol_form
ORDER BY operation, k_symbol_form;

-- 11. Client birth numbers: date of birth and gender in one field (50 added to a woman's month; century fixed at 19)
-- Expected: wrong_format 0, undecodable 0, 2,645 female and 2,724 male, born 1911-08-20 to 1987-09-27
WITH decoded AS (
    SELECT
        client_id,
        birth_number,
        CASE WHEN CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50 THEN 'F' ELSE 'M' END AS gender_code,
        STR_TO_DATE(
            CONCAT('19',
                   SUBSTRING(birth_number, 1, 2),
                   LPAD(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED)
                        - IF(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50, 50, 0), 2, '0'),
                   SUBSTRING(birth_number, 5, 2)),
            '%Y%m%d') AS birth_date
    FROM client_raw
)
SELECT
    COUNT(*)                                     AS total_clients,
    SUM(birth_number NOT REGEXP '^[0-9]{6}$')    AS wrong_format,
    SUM(birth_date IS NULL)                      AS undecodable,
    SUM(gender_code = 'F')                       AS coded_female,
    SUM(gender_code = 'M')                       AS coded_male,
    MIN(birth_date)                              AS oldest_born,
    MAX(birth_date)                              AS youngest_born
FROM decoded;

-- 11a. Age at the end of the data (1998-12-31) by role
-- Expected: 5,369 clients in total; 72 under 18 (57 owners, 15 authorised users); 4,500 owners
WITH decoded AS (
    SELECT
        client_id,
        STR_TO_DATE(
            CONCAT('19',
                   SUBSTRING(birth_number, 1, 2),
                   LPAD(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED)
                        - IF(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50, 50, 0), 2, '0'),
                   SUBSTRING(birth_number, 5, 2)),
            '%Y%m%d') AS birth_date
    FROM client_raw
),
client_ages AS (
    SELECT client_id, TIMESTAMPDIFF(YEAR, birth_date, '1998-12-31') AS age_at_end
    FROM decoded
)
SELECT
    CASE
        WHEN age_at_end < 18 THEN '1. under 18'
        WHEN age_at_end < 30 THEN '2. 18 to 29'
        WHEN age_at_end < 50 THEN '3. 30 to 49'
        WHEN age_at_end < 65 THEN '4. 50 to 64'
        ELSE '5. 65 and over'
    END                                   AS age_band,
    disp_raw.`type`                       AS disposition_type,
    COUNT(*)                              AS clients
FROM client_ages
JOIN disp_raw ON client_ages.client_id = disp_raw.client_id
GROUP BY age_band, disposition_type
ORDER BY age_band, disposition_type;

-- 12. Ranges of the amounts
-- Expected: no negatives except trans.balance (2,999); 14 zero-amount transactions
SELECT 'trans.amount' AS column_name, COUNT(*) AS total_rows,
       SUM(CAST(amount AS DECIMAL(14,2)) < 0) AS negative,
       SUM(CAST(amount AS DECIMAL(14,2)) = 0) AS zero,
       MIN(CAST(amount AS DECIMAL(14,2)))     AS smallest,
       MAX(CAST(amount AS DECIMAL(14,2)))     AS largest
FROM trans_raw
UNION ALL
SELECT 'trans.balance', COUNT(*),
       SUM(CAST(balance AS DECIMAL(14,2)) < 0), SUM(CAST(balance AS DECIMAL(14,2)) = 0),
       MIN(CAST(balance AS DECIMAL(14,2))), MAX(CAST(balance AS DECIMAL(14,2)))
FROM trans_raw
UNION ALL
SELECT 'loan.amount', COUNT(*),
       SUM(CAST(amount AS DECIMAL(14,2)) < 0), SUM(CAST(amount AS DECIMAL(14,2)) = 0),
       MIN(CAST(amount AS DECIMAL(14,2))), MAX(CAST(amount AS DECIMAL(14,2)))
FROM loan_raw
UNION ALL
SELECT 'loan.payments', COUNT(*),
       SUM(CAST(payments AS DECIMAL(14,2)) < 0), SUM(CAST(payments AS DECIMAL(14,2)) = 0),
       MIN(CAST(payments AS DECIMAL(14,2))), MAX(CAST(payments AS DECIMAL(14,2)))
FROM loan_raw
UNION ALL
SELECT 'loan.duration', COUNT(*),
       SUM(CAST(duration AS DECIMAL(14,2)) < 0), SUM(CAST(duration AS DECIMAL(14,2)) = 0),
       MIN(CAST(duration AS DECIMAL(14,2))), MAX(CAST(duration AS DECIMAL(14,2)))
FROM loan_raw
UNION ALL
SELECT 'order.amount', COUNT(*),
       SUM(CAST(amount AS DECIMAL(14,2)) < 0), SUM(CAST(amount AS DECIMAL(14,2)) = 0),
       MIN(CAST(amount AS DECIMAL(14,2))), MAX(CAST(amount AS DECIMAL(14,2)))
FROM order_raw;

-- 12a. The 14 zero-amount transactions
-- Expected: all interest postings (10 penalty-interest debits, 4 interest credits)
SELECT trans_id, account_id, STR_TO_DATE(`date`, '%y%m%d') AS trans_date,
       `type`, operation, amount, balance, k_symbol
FROM trans_raw
WHERE CAST(amount AS DECIMAL(14,2)) = 0
ORDER BY trans_date;

-- 12b. Who is behind the negative balances?
-- Expected: 288 accounts, 2,999 negative rows, at most 124 for one account
SELECT
    COUNT(*)                     AS accounts_ever_overdrawn,
    SUM(negative_rows)           AS negative_rows,
    MAX(negative_rows)           AS most_for_one_account,
    ROUND(AVG(negative_rows), 1) AS average_per_account
FROM (
    SELECT account_id, COUNT(*) AS negative_rows
    FROM trans_raw
    WHERE CAST(balance AS DECIMAL(14,2)) < 0
    GROUP BY account_id
) AS overdrawn_accounts;

-- 13. Do the loan figures agree? payments x duration against amount
-- Expected: 682 loans, none different (largest gap 0.0000): payments = amount / duration, no interest
SELECT
    COUNT(*)                                                         AS loans,
    SUM(ABS(payments * duration - amount) > 0.00)                    AS not_exactly_equal,
    SUM(ABS(payments * duration - amount) > 1.00)                    AS off_by_more_than_one,
    MAX(ABS(payments * duration - amount))                           AS largest_gap
FROM (
    SELECT
        CAST(amount   AS DECIMAL(14,2)) AS amount,
        CAST(payments AS DECIMAL(14,2)) AS payments,
        CAST(duration AS DECIMAL(14,2)) AS duration
    FROM loan_raw
) AS loan_numbers;

-- 14. Hidden duplicate transactions (identical except trans_id)
-- Expected: one group, one extra row (account 9051, 1998-02-28, amount 0)
SELECT
    COUNT(*)                                  AS duplicated_groups,
    SUM(copies - 1)                           AS extra_rows,
    SUM(CASE WHEN amount_value = 0 THEN copies - 1 ELSE 0 END) AS extra_rows_with_zero_amount,
    MAX(copies)                               AS most_copies_of_one
FROM (
    SELECT
        account_id, `date`, `type`, operation, amount, balance, k_symbol, bank, account,
        CAST(amount AS DECIMAL(14,2)) AS amount_value,
        COUNT(*)                      AS copies
    FROM trans_raw
    GROUP BY account_id, `date`, `type`, operation, amount, balance, k_symbol, bank, account
    HAVING COUNT(*) > 1
) AS repeated_rows;

-- 15. Balance against amount, on transactions whose order is certain
-- The file has no timestamps, so same-day order is unreliable. Keep only transactions that are alone on
-- their day and preceded by one that was alone on its day.
-- Expected: credits raise the balance and debits lower it (type VYBER is a debit); 98.7% follow their amount;
--           interest credits (blank operation) are the outlier (3,933 of 18,770 fail)
WITH day_counts AS (
    SELECT
        account_id,
        STR_TO_DATE(`date`, '%y%m%d')     AS trans_date,
        CAST(trans_id AS UNSIGNED)        AS trans_number,
        `type`,
        operation,
        CAST(amount  AS DECIMAL(14,2))    AS amount_value,
        CAST(balance AS DECIMAL(14,2))    AS balance_value,
        COUNT(*) OVER (PARTITION BY account_id, `date`) AS rows_that_day
    FROM trans_raw
),
with_previous AS (
    SELECT
        *,
        LAG(balance_value)  OVER (PARTITION BY account_id ORDER BY trans_date, trans_number) AS previous_balance,
        LAG(rows_that_day)  OVER (PARTITION BY account_id ORDER BY trans_date, trans_number) AS previous_rows_that_day
    FROM day_counts
)
SELECT
    `type`,
    operation,
    COUNT(*) AS unambiguous_rows,
    SUM(ABS((balance_value - previous_balance) - amount_value) < 0.005) AS balance_rose_by_amount,
    SUM(ABS((balance_value - previous_balance) + amount_value) < 0.005) AS balance_fell_by_amount,
    SUM(NOT (ABS((balance_value - previous_balance) - amount_value) < 0.005)
        AND NOT (ABS((balance_value - previous_balance) + amount_value) < 0.005)) AS neither
FROM with_previous
WHERE previous_balance IS NOT NULL
  AND rows_that_day = 1
  AND previous_rows_that_day = 1
GROUP BY `type`, operation
ORDER BY unambiguous_rows DESC;

-- 15a. The interest credits that do not move the balance by their amount
-- Expected: about 3,900 rows; balance change between 94.1% and 112.5% of the amount, averaging 100%
WITH day_counts AS (
    SELECT
        account_id,
        STR_TO_DATE(`date`, '%y%m%d')     AS trans_date,
        CAST(trans_id AS UNSIGNED)        AS trans_number,
        `type`,
        operation,
        CAST(amount  AS DECIMAL(14,2))    AS amount_value,
        CAST(balance AS DECIMAL(14,2))    AS balance_value,
        COUNT(*) OVER (PARTITION BY account_id, `date`) AS rows_that_day
    FROM trans_raw
),
with_previous AS (
    SELECT
        *,
        LAG(balance_value) OVER (PARTITION BY account_id ORDER BY trans_date, trans_number) AS previous_balance,
        LAG(rows_that_day) OVER (PARTITION BY account_id ORDER BY trans_date, trans_number) AS previous_rows_that_day
    FROM day_counts
)
SELECT
    COUNT(*)                                                              AS failing_interest_rows,
    ROUND(MIN((balance_value - previous_balance) / amount_value), 3)      AS lowest_change_to_amount,
    ROUND(AVG((balance_value - previous_balance) / amount_value), 3)      AS average_change_to_amount,
    ROUND(MAX((balance_value - previous_balance) / amount_value), 3)      AS highest_change_to_amount,
    ROUND(AVG(amount_value), 2)                                           AS average_interest_amount,
    ROUND(AVG(balance_value - previous_balance), 2)                       AS average_balance_change
FROM with_previous
WHERE previous_balance IS NOT NULL
  AND rows_that_day = 1
  AND previous_rows_that_day = 1
  AND `type` = 'PRIJEM'
  AND operation = ''
  AND amount_value > 0
  AND NOT (ABS((balance_value - previous_balance) - amount_value) < 0.005)
  AND NOT (ABS((balance_value - previous_balance) + amount_value) < 0.005);
