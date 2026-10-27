-- 01_load_raw.sql
-- Purpose: load the five Bank Dataset CSVs exactly as they appear in the files.
-- Builds:  database bank_analysis, with tables account_raw, branch_raw, customer_raw,
--          loan_raw and transaction_raw (all data columns text, no transformations)
-- Adds:    row_no, an AUTO_INCREMENT column that records each row's position in its file.
--          It is load metadata, not data. The files are three stacked batches whose IDs
--          restart at 1 (see docs/decision-log.md), and row_no is the only way to tell
--          the batches apart.
-- Note:    never UPDATE or DELETE on these tables after loading.
--          Column names keep the source file's spelling, including the typos
--          TRANSCATION_* in the transaction file; staging corrects them.
--
-- Before running:
--   1. Download the dataset (see data/README.md).
--   2. Find your MySQL upload folder by running:
--        SHOW VARIABLES LIKE 'secure_file_priv';
--   3. Copy the five CSV files into that folder.
--   4. Change the paths in LOAD DATA INFILE below to match it.
--      (The paths below are the author's own Windows path, shown as an example.)

CREATE DATABASE IF NOT EXISTS bank_analysis;
USE bank_analysis;

-- Accounts
DROP TABLE IF EXISTS account_raw;
CREATE TABLE account_raw (
    row_no            INT AUTO_INCREMENT PRIMARY KEY,
    ACCOUNT_ID        VARCHAR(50),
    CUSTOMER_ID       VARCHAR(50),
    BRANCH_ID         VARCHAR(50),
    OPENING_BALANCE   VARCHAR(50),
    ACCOUNT_OPEN_DATE VARCHAR(50),
    ACCOUNT_TYPE      VARCHAR(100),
    ACCOUNT_STATUS    VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Account_Data.csv'
INTO TABLE account_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ACCOUNT_ID, CUSTOMER_ID, BRANCH_ID, OPENING_BALANCE, ACCOUNT_OPEN_DATE, ACCOUNT_TYPE, ACCOUNT_STATUS);

-- Branches
DROP TABLE IF EXISTS branch_raw;
CREATE TABLE branch_raw (
    row_no       INT AUTO_INCREMENT PRIMARY KEY,
    BRANCH_ID    VARCHAR(50),
    BRANCH_NAME  VARCHAR(200),
    BRANCH_STATE VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Branch_Data.csv'
INTO TABLE branch_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(BRANCH_ID, BRANCH_NAME, BRANCH_STATE);

-- Customers
DROP TABLE IF EXISTS customer_raw;
CREATE TABLE customer_raw (
    row_no       INT AUTO_INCREMENT PRIMARY KEY,
    CUSTOMER_ID  VARCHAR(50),
    First_Name   VARCHAR(200),
    Last_Name    VARCHAR(200),
    City         VARCHAR(200),
    Phone_Number VARCHAR(50),
    Occupation   VARCHAR(200),
    DOB          VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Customer_Data.csv'
INTO TABLE customer_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(CUSTOMER_ID, First_Name, Last_Name, City, Phone_Number, Occupation, DOB);

-- Loans
DROP TABLE IF EXISTS loan_raw;
CREATE TABLE loan_raw (
    row_no      INT AUTO_INCREMENT PRIMARY KEY,
    LOAN_ID     VARCHAR(50),
    CUSTOMER_ID VARCHAR(50),
    BRANCH_ID   VARCHAR(50),
    LOAN_AMOUNT VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Loan_Data.csv'
INTO TABLE loan_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(LOAN_ID, CUSTOMER_ID, BRANCH_ID, LOAN_AMOUNT);

-- Transactions (the source file and its columns are spelled "Transacation" / "TRANSCATION")
DROP TABLE IF EXISTS transaction_raw;
CREATE TABLE transaction_raw (
    row_no             INT AUTO_INCREMENT PRIMARY KEY,
    TRANSCATION_ID     VARCHAR(50),
    ACCOUNT_ID         VARCHAR(50),
    TRANSCATION_DATE   VARCHAR(50),
    TRANSCATION_MEDIA  VARCHAR(100),
    TRANSCATION_TYPE   VARCHAR(100),
    TRANSCATION_AMOUNT VARCHAR(50)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Transacation_Data.csv'
INTO TABLE transaction_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(TRANSCATION_ID, ACCOUNT_ID, TRANSCATION_DATE, TRANSCATION_MEDIA, TRANSCATION_TYPE, TRANSCATION_AMOUNT);
