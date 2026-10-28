-- 04_profile_staging.sql
-- Purpose: check that the staging tables match the raw tables and that every conversion worked.
-- Reads:   the *_stg tables in czech_bank
-- Expected: row counts equal the raw counts (4,500 | 892 | 5,369 | 5,369 | 77 | 682 | 6,471 | 1,056,320)
--           and 0 for both failure lines.

USE czech_bank;

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
