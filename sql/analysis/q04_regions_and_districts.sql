-- q04_regions_and_districts.sql
-- Question: Which regions and districts hold the most accounts and the highest balances?
-- Reads:    account_stg, district_stg, trans_stg
-- Note:     the balance is each account's average recorded balance; the file has no timestamps, so
--           "latest balance" is unreliable. Accounts per 1,000 inhabitants adjusts for population.

USE czech_bank;

-- By region
WITH account_balance AS (
    SELECT account_id, AVG(balance) AS avg_balance
    FROM trans_stg
    GROUP BY account_id
),
region_accounts AS (
    SELECT
        district_stg.region,
        COUNT(*)                          AS accounts,
        AVG(account_balance.avg_balance)  AS avg_account_balance
    FROM account_stg
    JOIN district_stg ON account_stg.district_id = district_stg.district_id
    JOIN account_balance ON account_stg.account_id = account_balance.account_id
    GROUP BY district_stg.region
),
region_population AS (
    SELECT region, SUM(inhabitants) AS inhabitants, ROUND(AVG(average_salary)) AS average_salary
    FROM district_stg
    GROUP BY region
)
SELECT
    region_accounts.region,
    region_accounts.accounts,
    region_population.inhabitants,
    ROUND(region_accounts.accounts * 1000 / region_population.inhabitants, 2) AS accounts_per_1000_inhabitants,
    region_population.average_salary,
    ROUND(region_accounts.avg_account_balance)                               AS avg_account_balance
FROM region_accounts
JOIN region_population ON region_accounts.region = region_population.region
ORDER BY region_accounts.accounts DESC;

-- Top 10 districts by number of accounts
SELECT
    district_stg.district_name,
    district_stg.region,
    COUNT(*)                                                    AS accounts,
    district_stg.inhabitants,
    ROUND(COUNT(*) * 1000 / district_stg.inhabitants, 2)        AS accounts_per_1000_inhabitants,
    district_stg.average_salary
FROM account_stg
JOIN district_stg ON account_stg.district_id = district_stg.district_id
GROUP BY district_stg.district_id, district_stg.district_name, district_stg.region,
         district_stg.inhabitants, district_stg.average_salary
ORDER BY accounts DESC
LIMIT 10;
