-- 01_load_raw.sql
-- Purpose: load the eight Berka (PKDD'99) files exactly as they appear in the source.
-- Builds:  database czech_bank, with one *_raw table per file (all data columns text,
--          no transformations): account, card, client, disp, district, loan, order, trans
-- Adds:    row_no, an AUTO_INCREMENT column that records each row's position in its file.
--          It is load metadata, not data.
-- Format:  semicolon-delimited, text in double quotes, CRLF line endings, one header line.
-- Note:    never UPDATE or DELETE on these tables after loading.
--          Empty fields load as empty strings, not NULL, so missing values stay visible.
--          district columns keep the file's own names (A1 to A16); staging renames them.
--          The order table is called order_raw because ORDER is a reserved word.
--
-- Before running:
--   1. Download the original .asc files (see data/README.md).
--   2. Find your MySQL upload folder by running:
--        SHOW VARIABLES LIKE 'secure_file_priv';
--   3. Copy the eight .asc files into that folder.
--   4. Change the paths in LOAD DATA INFILE below to match it.
--      (The paths below are the author's own Windows path, shown as an example.)
--   5. trans.asc has about 1.06 million rows. If Workbench drops the connection, raise
--      Edit > Preferences > SQL Editor > "DBMS connection read timeout" (for example to 600).

CREATE DATABASE IF NOT EXISTS czech_bank;
USE czech_bank;

-- Accounts
DROP TABLE IF EXISTS account_raw;
CREATE TABLE account_raw (
    row_no      INT AUTO_INCREMENT PRIMARY KEY,
    account_id  VARCHAR(50),
    district_id VARCHAR(50),
    frequency   VARCHAR(100),
    `date`      VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\account.asc'
INTO TABLE account_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(account_id, district_id, frequency, `date`);

-- Cards
DROP TABLE IF EXISTS card_raw;
CREATE TABLE card_raw (
    row_no  INT AUTO_INCREMENT PRIMARY KEY,
    card_id VARCHAR(50),
    disp_id VARCHAR(50),
    `type`  VARCHAR(100),
    issued  VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\card.asc'
INTO TABLE card_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(card_id, disp_id, `type`, issued);

-- Clients
DROP TABLE IF EXISTS client_raw;
CREATE TABLE client_raw (
    row_no       INT AUTO_INCREMENT PRIMARY KEY,
    client_id    VARCHAR(50),
    birth_number VARCHAR(50),
    district_id  VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\client.asc'
INTO TABLE client_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(client_id, birth_number, district_id);

-- Dispositions (which client can operate which account)
DROP TABLE IF EXISTS disp_raw;
CREATE TABLE disp_raw (
    row_no     INT AUTO_INCREMENT PRIMARY KEY,
    disp_id    VARCHAR(50),
    client_id  VARCHAR(50),
    account_id VARCHAR(50),
    `type`     VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\disp.asc'
INTO TABLE disp_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(disp_id, client_id, account_id, `type`);

-- Districts (demographic data; the source file has no real column names)
DROP TABLE IF EXISTS district_raw;
CREATE TABLE district_raw (
    row_no INT AUTO_INCREMENT PRIMARY KEY,
    A1  VARCHAR(100),
    A2  VARCHAR(100),
    A3  VARCHAR(100),
    A4  VARCHAR(100),
    A5  VARCHAR(100),
    A6  VARCHAR(100),
    A7  VARCHAR(100),
    A8  VARCHAR(100),
    A9  VARCHAR(100),
    A10 VARCHAR(100),
    A11 VARCHAR(100),
    A12 VARCHAR(100),
    A13 VARCHAR(100),
    A14 VARCHAR(100),
    A15 VARCHAR(100),
    A16 VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\district.asc'
INTO TABLE district_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16);

-- Loans
DROP TABLE IF EXISTS loan_raw;
CREATE TABLE loan_raw (
    row_no     INT AUTO_INCREMENT PRIMARY KEY,
    loan_id    VARCHAR(50),
    account_id VARCHAR(50),
    `date`     VARCHAR(50),
    amount     VARCHAR(50),
    duration   VARCHAR(50),
    payments   VARCHAR(50),
    status     VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\loan.asc'
INTO TABLE loan_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(loan_id, account_id, `date`, amount, duration, payments, status);

-- Standing orders
DROP TABLE IF EXISTS order_raw;
CREATE TABLE order_raw (
    row_no     INT AUTO_INCREMENT PRIMARY KEY,
    order_id   VARCHAR(50),
    account_id VARCHAR(50),
    bank_to    VARCHAR(50),
    account_to VARCHAR(50),
    amount     VARCHAR(50),
    k_symbol   VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\order.asc'
INTO TABLE order_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(order_id, account_id, bank_to, account_to, amount, k_symbol);

-- Transactions (about 1.06 million rows; this load takes the longest)
DROP TABLE IF EXISTS trans_raw;
CREATE TABLE trans_raw (
    row_no     INT AUTO_INCREMENT PRIMARY KEY,
    trans_id   VARCHAR(50),
    account_id VARCHAR(50),
    `date`     VARCHAR(50),
    `type`     VARCHAR(50),
    operation  VARCHAR(50),
    amount     VARCHAR(50),
    balance    VARCHAR(50),
    k_symbol   VARCHAR(50),
    bank       VARCHAR(50),
    account    VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\trans.asc'
INTO TABLE trans_raw
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(trans_id, account_id, `date`, `type`, operation, amount, balance, k_symbol, bank, account);
