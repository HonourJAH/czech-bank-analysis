-- 01_load_raw.sql
-- Purpose: load the five Bank Dataset CSVs exactly as they appear in the files.
-- Builds:  database bank_analysis, with tables account_raw, branch_raw, customer_raw,
--          loan_raw and transaction_raw (all columns text, no transformations)
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
IGNORE 1 LINES;

-- Branches
DROP TABLE IF EXISTS branch_raw;
CREATE TABLE branch_raw (
    BRANCH_ID    VARCHAR(50),
    BRANCH_NAME  VARCHAR(200),
    BRANCH_STATE VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bank_Branch_Data.csv'
INTO TABLE branch_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Customers
DROP TABLE IF EXISTS customer_raw;
CREATE TABLE customer_raw (
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
IGNORE 1 LINES;

-- Loans
DROP TABLE IF EXISTS loan_raw;
CREATE TABLE loan_raw (
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
IGNORE 1 LINES;

-- Transactions (the source file and its columns are spelled "Transacation" / "TRANSCATION")
DROP TABLE IF EXISTS transaction_raw;
CREATE TABLE transaction_raw (
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
IGNORE 1 LINES;
