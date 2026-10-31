# Czech Bank Analysis: Profiling, Cleaning and Insights on Real Bank Data in MySQL

An end-to-end SQL analysis of a real, anonymised Czech bank (the Berka / PKDD'99 dataset, 1993 to 1998): eight related tables with over a million transactions. The project profiles the raw files in depth, documents every decision in an auditable log, and answers ten business questions on growth, money flow, products, regions, loans, cards, account segments and overdrafts.

**Status:** complete. Data profiling, staging, the decision log and all ten business questions are done.

## Dataset

- **Source:** the PKDD'99 Discovery Challenge financial data, also described at https://relational.fel.cvut.cz/dataset/Financial
- **Size:** 8 tables, 1,056,320 transactions on 4,500 accounts held by 5,369 clients, 682 loans, 892 cards, 6,471 standing orders and 77 districts, 1993 to 1998
- The original `.asc` files are not included in this repository. See `data/README.md` for how to download them.
- The currency is not stated in the files; the bank is Czech, so amounts are presumably Czech koruna, which is an assumption.
- Column values are in Czech (for example PRIJEM for credit and VYDAJ for debit). Staging decodes them to English labels and keeps the original code next to each label.

## Tools

- MySQL 8.0 (SQL: CTEs, window functions, conditional aggregation, joins)
- Git and GitHub

## Approach

The raw files are loaded unchanged into all-text tables, profiled, and then converted in a staging layer. Profiling found nothing to exclude, so the staging tables are the analysis layer: every staging table has the same row count as its raw table, and recomputing blank counts, decoded values and totals from raw gives identical figures.

| Layer | Tables | Purpose |
|---|---|---|
| Raw | `account_raw`, `card_raw`, `client_raw`, `disp_raw`, `district_raw`, `loan_raw`, `order_raw`, `trans_raw` | The files exactly as loaded, all text. Never changed. |
| Staging | `*_stg` | Typed, decoded and NULL-cleaned copies; the analysis layer. |

## What profiling found

The full evidence behind each decision is in `docs/decision-log.md`.

| # | Finding | Decision |
|---|---|---|
| 1 | All eight IDs are unique and all eight foreign-key relationships resolve (zero orphans) | No key problems; joins cannot multiply or drop rows |
| 2 | Blank values in `trans` follow rules: 183,114 blank operations are all automatic interest credits | Keep; blanks become NULL |
| 3 | Two forms of blank (empty and a single space) in the payment-purpose code | Trim, then treat both as NULL |
| 4 | District 69 has "?" in two numeric columns, which an empty-field check does not detect | Become NULL; nothing estimated |
| 5 | Dates are YYMMDD text with no century; all valid and in order (no record before its account opened) | Convert to DATE (1993 to 1998) |
| 6 | Client birth numbers hide date of birth and gender (50 added to a woman's month) | Decode to `birth_date` and `gender` |
| 7 | 14 zero-amount transactions, all interest postings | Keep |
| 8 | Negative balances on 288 accounts (6.4%), a legitimate overdraft state | Keep |
| 9 | Loan payment equals amount divided by duration for all 682 loans (no interest in the data) | No claims about loan cost or profit |
| 10 | Amounts and balances agree on 98.7% of transactions whose order is certain; the file has no timestamps, so same-day order is unreliable | Use recorded balances; do not recompute them |

## Key findings
Full write-ups for each question are in [`docs/findings.md`](docs/findings.md).

1. **Growth.** 4,500 accounts were opened in waves, peaking at 1,363 in 1996 (30.3%), and none after 29 December 1997. About 235 transactions per account.
2. **Money flow.** Customers deposited more than they withdrew in every year (a net inflow of about 197.2M), but the share of incoming money that stayed fell from 8.2% in 1996 to 2.8% in 1998. In 1998, with no new accounts, transactions still rose 13.3%.
3. **Channels.** Cash dominates: deposits and withdrawals are 56.0% of transactions and 76.0% of the value. Card withdrawals are 0.8% of transactions. 87.6% of the money moved has no recorded purpose.
4. **Regions.** North and south Moravia hold 34.9% of accounts; Prague alone holds 12.3%. Salaries differ much more across regions than balances do (Prague's salary is 45.6% above east Bohemia's, but its balance only 4.5% above).
5. **Loan portfolio.** 103.3M lent across 682 loans; 76 (11.1%) ended in trouble but they are 15.1% of the money, because problem loans are larger. The 45 loans now in debt average 249,285, more than 2.7 times the loans that finished paid.
6. **Loan size, not term.** Loans of 200,000 or more fail about 2.3 times as often (18.9% against 8.2%) and account for 46.1% of problem loans. Duration matters little. Excluding the immature 1998 loans, the problem rate is 13.7%.
7. **Borrowers and districts.** Age, gender, district salary and district unemployment show no difference larger than chance in loan outcomes (rates between 10.1% and 12.3% against 11.1% overall).
8. **Cards.** Card holders are 19.8% of accounts but average 76% more money out and 57% higher balances. Half of all cards were issued in 1998. An association, not a proven effect of the card.
9. **Account segments.** High-activity, high-balance accounts are 32.8% of accounts but 57.7% of money in; the two high-balance segments bring in 76.4%.
10. **Overdrafts.** All 27 loans granted on accounts that had already been overdrawn became problem loans (against 7.5% for the rest), a warning sign that would have flagged 35.5% of problem loans in advance. The overdraft status over the whole life of the account is not independent of the loan status, so only the overdraft before the loan is informative. 27 loans is a small group.

## Business questions answered

| # | Question | Script |
|---|---|---|
| 1 | How big is the bank, and how did it grow? | `q01_size_and_growth.sql` |
| 2 | How much money moved in and out each year? | `q02_money_flow_by_year.sql` |
| 3 | What kinds of transaction make up the activity? | `q03_transaction_mix.sql` |
| 4 | Which regions and districts hold the most accounts? | `q04_regions_and_districts.sql` |
| 5 | How large is the loan portfolio, and how many loans ended in trouble? | `q05_loan_portfolio.sql` |
| 6 | Does the loan outcome differ by size, term and year? | `q06_loan_outcome_by_size_and_term.sql` |
| 7 | Does the loan outcome differ by client and district? | `q07_loan_outcome_by_client_and_district.sql` |
| 8 | How many cards, and do card holders behave differently? | `q08_cards.sql` |
| 9 | How can accounts be segmented by activity and balance? | `q09_account_segments.sql` |
| 10 | Do overdrafts relate to loan trouble? | `q10_overdrafts_and_loan_trouble.sql` |

## Repository structure

```
sql/            numbered pipeline scripts, run in order (01 to 04)
sql/analysis/   one script per business question (q01 to q10)
data/           instructions for the dataset (the files themselves are not committed)
docs/           the decision log
```

## How to reproduce

1. Download the dataset and place the `.asc` files as described in `data/README.md`.
2. Follow the setup notes at the top of `sql/01_load_raw.sql` (the file path must match your MySQL upload folder).
3. Run the scripts in `sql/` in numbered order, then the queries in `sql/analysis/`.

## Limitations

- The loan table has no interest figure, so the analysis measures credit risk but not profit or the cost of credit.
- The file has no timestamps, so the order of transactions within one day is unreliable; balance-based results use the recorded balances.
- The data is old (1993 to 1998) and from one bank; the accounts are a sample, so regional figures show how the bank is spread, not its market share.
- 76 problem loans make small groups noisy; differences are flagged as meaningful only when clearly larger than chance.
- Segment boundaries and the overdraft-and-loan relationship are analytical choices, documented in each script.

## Author

Michael Onojah ([@HonourJAH](https://github.com/HonourJAH))
