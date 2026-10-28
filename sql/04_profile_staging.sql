-- 04_profile_staging.sql
-- Purpose: check that the staging tables match the raw tables and that every conversion worked.
-- Reads:   the *_stg and *_raw tables in czech_bank
-- Check 1: row counts equal the raw counts (4,500 | 892 | 5,369 | 5,369 | 77 | 682 | 6,471 | 1,056,320)
--          and 0 for both failure lines.
-- Check 2: each figure recomputed from raw by a different route equals the staging figure
--          (staging_value = raw_value on every line).

USE czech_bank;

-- Check 1: row counts, dates that failed to convert and codes without a label
SELECT 'account_stg rows' AS check_name, COUNT(*) AS result FROM account_stg
UNION ALL SELECT 'card_stg rows',                  COUNT(*) FROM card_stg
UNION ALL SELECT 'client_stg rows',                COUNT(*) FROM client_stg
UNION ALL SELECT 'disp_stg rows',                  COUNT(*) FROM disp_stg
UNION ALL SELECT 'district_stg rows',              COUNT(*) FROM district_stg
UNION ALL SELECT 'loan_stg rows',                  COUNT(*) FROM loan_stg
UNION ALL SELECT 'order_stg rows',                 COUNT(*) FROM order_stg
UNION ALL SELECT 'trans_stg rows',                 COUNT(*) FROM trans_stg
UNION ALL SELECT 'dates that failed to convert',
       (SELECT SUM(open_date IS NULL) FROM account_stg)
     + (SELECT SUM(issued_date IS NULL) FROM card_stg)
     + (SELECT SUM(loan_date IS NULL) FROM loan_stg)
     + (SELECT SUM(birth_date IS NULL) FROM client_stg)
     + (SELECT SUM(trans_date IS NULL) FROM trans_stg)
UNION ALL SELECT 'codes without a label',
       (SELECT SUM(statement_frequency IS NULL) FROM account_stg)
     + (SELECT SUM(role IS NULL) FROM disp_stg)
     + (SELECT SUM(status IS NULL) FROM loan_stg)
     + (SELECT SUM(operation IS NULL AND operation_code IS NOT NULL) FROM trans_stg)
     + (SELECT SUM(purpose IS NULL AND purpose_code IS NOT NULL) FROM trans_stg)
     + (SELECT SUM(purpose IS NULL AND purpose_code IS NOT NULL) FROM order_stg);

-- Check 2: staging against raw, one pair of numbers per line
-- Known values: blank operation 183,114 | blank purpose 535,314 | blank partner bank 782,812 |
--               blank partner account 760,931 | order purpose 1,379 | district placeholders 1 and 1 |
--               women 2,645. The four totals have no reference value but must match each other.
SELECT 'trans: blank operation -> NULL' AS check_name,
       (SELECT SUM(operation_code IS NULL) FROM trans_stg)          AS staging_value,
       (SELECT SUM(TRIM(operation) = '')   FROM trans_raw)          AS raw_value
UNION ALL SELECT 'trans: blank purpose -> NULL',
       (SELECT SUM(purpose_code IS NULL) FROM trans_stg),
       (SELECT SUM(TRIM(k_symbol) = '')  FROM trans_raw)
UNION ALL SELECT 'trans: blank partner bank -> NULL',
       (SELECT SUM(partner_bank IS NULL) FROM trans_stg),
       (SELECT SUM(TRIM(bank) = '')      FROM trans_raw)
UNION ALL SELECT 'trans: blank partner account -> NULL',
       (SELECT SUM(partner_account IS NULL) FROM trans_stg),
       (SELECT SUM(TRIM(account) = '')      FROM trans_raw)
UNION ALL SELECT 'order: blank purpose -> NULL',
       (SELECT SUM(purpose_code IS NULL) FROM order_stg),
       (SELECT SUM(TRIM(k_symbol) = '')  FROM order_raw)
UNION ALL SELECT 'district: ? -> NULL (unemployment 1995)',
       (SELECT SUM(unemployment_rate_1995 IS NULL) FROM district_stg),
       (SELECT SUM(A12 = '?') FROM district_raw)
UNION ALL SELECT 'district: ? -> NULL (crimes 1995)',
       (SELECT SUM(crimes_1995 IS NULL) FROM district_stg),
       (SELECT SUM(A15 = '?') FROM district_raw)
UNION ALL SELECT 'client: women decoded from birth number',
       (SELECT SUM(gender = 'female') FROM client_stg),
       (SELECT SUM(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50) FROM client_raw)
UNION ALL SELECT 'trans: total amount',
       (SELECT SUM(amount)  FROM trans_stg),
       (SELECT SUM(CAST(amount AS DECIMAL(14,2)))  FROM trans_raw)
UNION ALL SELECT 'trans: total balance',
       (SELECT SUM(balance) FROM trans_stg),
       (SELECT SUM(CAST(balance AS DECIMAL(14,2))) FROM trans_raw)
UNION ALL SELECT 'loan: total amount',
       (SELECT SUM(amount)  FROM loan_stg),
       (SELECT SUM(CAST(amount AS DECIMAL(14,2)))  FROM loan_raw)
UNION ALL SELECT 'order: total amount',
       (SELECT SUM(amount)  FROM order_stg),
       (SELECT SUM(CAST(amount AS DECIMAL(14,2)))  FROM order_raw);
