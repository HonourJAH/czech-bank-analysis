-- 03_build_staging.sql
-- Purpose: typed and decoded copies of the raw tables. No rows are removed: every staging table has
--          the same row count as its raw table.
-- Reads:   the *_raw tables in czech_bank
-- Builds:  district_stg, account_stg, client_stg, disp_stg, card_stg, loan_stg, order_stg, trans_stg
-- Rules (see docs/decision-log.md):
--   * dates: YYMMDD text becomes DATE, with 93 to 98 meaning 1993 to 1998
--   * blanks and single spaces become NULL (TRIM, then NULLIF)
--   * '?' in district columns becomes NULL
--   * Czech codes are decoded to English labels; the original code is kept next to each label
--   * client birth_number is decoded to birth_date and gender (century fixed at 19)
-- Note:    trans_stg has about 1.06 million rows. If Workbench drops the connection, raise
--          Edit > Preferences > SQL Editor > "DBMS connection read timeout".

USE czech_bank;

-- Districts: the source file has no real column names, so A1 to A16 are renamed from the dataset description.
DROP TABLE IF EXISTS district_stg;
CREATE TABLE district_stg AS
SELECT
    CAST(A1 AS UNSIGNED)                                   AS district_id,
    A2                                                     AS district_name,
    A3                                                     AS region,
    CAST(A4 AS UNSIGNED)                                   AS inhabitants,
    CAST(A5 AS UNSIGNED)                                   AS municipalities_under_500,
    CAST(A6 AS UNSIGNED)                                   AS municipalities_500_to_1999,
    CAST(A7 AS UNSIGNED)                                   AS municipalities_2000_to_9999,
    CAST(A8 AS UNSIGNED)                                   AS municipalities_10000_and_over,
    CAST(A9 AS UNSIGNED)                                   AS cities,
    CAST(A10 AS DECIMAL(5,1))                              AS urban_inhabitants_pct,
    CAST(A11 AS UNSIGNED)                                  AS average_salary,
    CAST(NULLIF(TRIM(A12), '?') AS DECIMAL(5,2))           AS unemployment_rate_1995,
    CAST(NULLIF(TRIM(A13), '?') AS DECIMAL(5,2))           AS unemployment_rate_1996,
    CAST(A14 AS UNSIGNED)                                  AS entrepreneurs_per_1000,
    CAST(NULLIF(TRIM(A15), '?') AS UNSIGNED)               AS crimes_1995,
    CAST(NULLIF(TRIM(A16), '?') AS UNSIGNED)               AS crimes_1996
FROM district_raw;

-- Accounts
DROP TABLE IF EXISTS account_stg;
CREATE TABLE account_stg AS
SELECT
    CAST(account_id AS UNSIGNED)                           AS account_id,
    CAST(district_id AS UNSIGNED)                          AS district_id,
    frequency                                              AS statement_frequency_code,
    CASE frequency
        WHEN 'POPLATEK MESICNE'   THEN 'monthly'
        WHEN 'POPLATEK TYDNE'     THEN 'weekly'
        WHEN 'POPLATEK PO OBRATU' THEN 'after_transaction'
    END                                                    AS statement_frequency,
    STR_TO_DATE(`date`, '%y%m%d')                          AS open_date
FROM account_raw;

-- Clients: birth_number holds the date of birth and the gender (50 is added to a woman's month)
DROP TABLE IF EXISTS client_stg;
CREATE TABLE client_stg AS
SELECT
    CAST(client_id AS UNSIGNED)                            AS client_id,
    STR_TO_DATE(
        CONCAT('19',
               SUBSTRING(birth_number, 1, 2),
               LPAD(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED)
                    - IF(CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50, 50, 0), 2, '0'),
               SUBSTRING(birth_number, 5, 2)),
        '%Y%m%d')                                          AS birth_date,
    CASE WHEN CAST(SUBSTRING(birth_number, 3, 2) AS UNSIGNED) > 50 THEN 'female' ELSE 'male' END AS gender,
    CAST(district_id AS UNSIGNED)                          AS district_id
FROM client_raw;

-- Dispositions: which client can operate which account, and in what role
DROP TABLE IF EXISTS disp_stg;
CREATE TABLE disp_stg AS
SELECT
    CAST(disp_id AS UNSIGNED)                              AS disp_id,
    CAST(client_id AS UNSIGNED)                            AS client_id,
    CAST(account_id AS UNSIGNED)                           AS account_id,
    `type`                                                 AS role_code,
    CASE `type`
        WHEN 'OWNER'     THEN 'owner'
        WHEN 'DISPONENT' THEN 'authorised_user'
    END                                                    AS role
FROM disp_raw;

-- Cards (the issued column is YYMMDD followed by a constant " 00:00:00", which is dropped)
DROP TABLE IF EXISTS card_stg;
CREATE TABLE card_stg AS
SELECT
    CAST(card_id AS UNSIGNED)                              AS card_id,
    CAST(disp_id AS UNSIGNED)                              AS disp_id,
    `type`                                                 AS card_type,
    STR_TO_DATE(LEFT(issued, 6), '%y%m%d')                 AS issued_date
FROM card_raw;

-- Loans (payments equals amount divided by duration for every loan, so it carries no extra information)
DROP TABLE IF EXISTS loan_stg;
CREATE TABLE loan_stg AS
SELECT
    CAST(loan_id AS UNSIGNED)                              AS loan_id,
    CAST(account_id AS UNSIGNED)                           AS account_id,
    STR_TO_DATE(`date`, '%y%m%d')                          AS loan_date,
    CAST(amount AS DECIMAL(12,2))                          AS amount,
    CAST(duration AS UNSIGNED)                             AS duration_months,
    CAST(payments AS DECIMAL(12,2))                        AS monthly_payment,
    status                                                 AS status_code,
    CASE status
        WHEN 'A' THEN 'finished_paid'
        WHEN 'B' THEN 'finished_unpaid'
        WHEN 'C' THEN 'running_ok'
        WHEN 'D' THEN 'running_in_debt'
    END                                                    AS status
FROM loan_raw;

-- Standing orders
DROP TABLE IF EXISTS order_stg;
CREATE TABLE order_stg AS
SELECT
    CAST(order_id AS UNSIGNED)                             AS order_id,
    CAST(account_id AS UNSIGNED)                           AS account_id,
    bank_to,
    account_to,
    CAST(amount AS DECIMAL(12,2))                          AS amount,
    NULLIF(TRIM(k_symbol), '')                             AS purpose_code,
    CASE NULLIF(TRIM(k_symbol), '')
        WHEN 'SIPO'     THEN 'household_payment'
        WHEN 'UVER'     THEN 'loan_payment'
        WHEN 'POJISTNE' THEN 'insurance_payment'
        WHEN 'LEASING'  THEN 'leasing_payment'
    END                                                    AS purpose
FROM order_raw;

-- Transactions
DROP TABLE IF EXISTS trans_stg;
CREATE TABLE trans_stg AS
SELECT
    CAST(trans_id AS UNSIGNED)                             AS trans_id,
    CAST(account_id AS UNSIGNED)                           AS account_id,
    STR_TO_DATE(`date`, '%y%m%d')                          AS trans_date,
    `type`                                                 AS type_code,
    CASE WHEN `type` = 'PRIJEM' THEN 'credit' ELSE 'debit' END AS direction,
    NULLIF(TRIM(operation), '')                            AS operation_code,
    CASE NULLIF(TRIM(operation), '')
        WHEN 'VKLAD'          THEN 'cash_deposit'
        WHEN 'PREVOD Z UCTU'  THEN 'transfer_in'
        WHEN 'PREVOD NA UCET' THEN 'transfer_out'
        WHEN 'VYBER'          THEN 'cash_withdrawal'
        WHEN 'VYBER KARTOU'   THEN 'card_withdrawal'
    END                                                    AS operation,
    CAST(amount AS DECIMAL(12,2))                          AS amount,
    CAST(balance AS DECIMAL(12,2))                         AS balance,
    NULLIF(TRIM(k_symbol), '')                             AS purpose_code,
    CASE NULLIF(TRIM(k_symbol), '')
        WHEN 'UROK'        THEN 'interest_credited'
        WHEN 'SANKC. UROK' THEN 'penalty_interest'
        WHEN 'SLUZBY'      THEN 'statement_fee'
        WHEN 'SIPO'        THEN 'household_payment'
        WHEN 'DUCHOD'      THEN 'old_age_pension'
        WHEN 'POJISTNE'    THEN 'insurance_payment'
        WHEN 'UVER'        THEN 'loan_payment'
    END                                                    AS purpose,
    NULLIF(TRIM(bank), '')                                 AS partner_bank,
    NULLIF(TRIM(account), '')                              AS partner_account
FROM trans_raw;

-- Keys and indexes, so joins on a million rows stay fast
ALTER TABLE district_stg ADD PRIMARY KEY (district_id);
ALTER TABLE account_stg  ADD PRIMARY KEY (account_id);
ALTER TABLE client_stg   ADD PRIMARY KEY (client_id);
ALTER TABLE disp_stg     ADD PRIMARY KEY (disp_id), ADD INDEX (account_id), ADD INDEX (client_id);
ALTER TABLE card_stg     ADD PRIMARY KEY (card_id), ADD INDEX (disp_id);
ALTER TABLE loan_stg     ADD PRIMARY KEY (loan_id), ADD INDEX (account_id);
ALTER TABLE order_stg    ADD PRIMARY KEY (order_id), ADD INDEX (account_id);
ALTER TABLE trans_stg    ADD PRIMARY KEY (trans_id), ADD INDEX (account_id), ADD INDEX (trans_date);
