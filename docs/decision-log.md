# Decision log: Berka (Czech bank) cleaning

Every cleaning decision in this project, with the evidence that led to it. Nothing is removed
silently, and every count below can be reproduced with the scripts in `sql/`.

Czech terms in the data (for example PRIJEM, VYDAJ, UROK) are decoded using the dataset's published
description. Check the glossary against the source before relying on a meaning.

## Load

- The eight original `.asc` files are loaded unchanged into `*_raw` tables, all data columns text
  (`sql/01_load_raw.sql`). Format: semicolon-delimited, quoted text, CRLF line endings, one header line.
- Row counts match the file line counts minus headers: account 4,500, card 892, client 5,369, disp 5,369,
  district 77, loan 682, order 6,471, trans 1,056,320.

## 1. Keys: all IDs are unique and every reference resolves

- All eight primary IDs are unique (no repeated rows in any table).
- All eight foreign-key relationships have zero orphans: account and client to district, disp to client and
  account, card to disp, and loan, order and trans to account.
- Decision: no key problems; joins on these IDs cannot multiply or drop rows.

## 2. Blank values in trans (1,056,320 rows)

| Column | Blank rows | Share |
|---|---|---|
| operation | 183,114 | 17.3% |
| k_symbol | 535,314 | 50.7% |
| bank | 782,812 | 74.1% |
| account | 760,931 | 72.0% |

- ID, date, type, amount and balance columns have no blanks.
- All 183,114 blank `operation` rows are `type = PRIJEM` (credit) with `k_symbol = UROK` (interest credited):
  an automatic posting with no teller, card or transfer operation. A blank here means "not applicable".
- Partner bank and account are blank for deposits, interest credits and cash withdrawals typed VYBER, and
  present for transfers (one outgoing transfer has neither).
- 21,881 withdrawals carry a partner account number but no partner bank (13,845 cash withdrawals and all
  8,036 card withdrawals). The meaning is not documented here.
- `k_symbol` (payment purpose) is optional and blank in many groups.
- Decision: keep every row. In staging, blanks become NULL. The partner `bank` and `account` columns are not
  used in the analysis.

## 3. Blank values elsewhere

- All other columns in the seven smaller tables are complete except `order.k_symbol`, blank on 1,379 of
  6,471 standing orders (21.3%). It is the same optional payment-purpose field.
- Decision: keep the rows; blanks become NULL in staging.

## 4. District 69 (Jesenik) has "?" in two numeric columns

- Columns A12 and A15 hold `?` for district 69. It is the only non-numeric value in the numeric district
  columns, and an empty-field check does not detect it.
- A12 and A15 are the 1995 unemployment rate and 1995 crime count; the 1996 values (A13, A16) are present.
- Decision: both become NULL in staging. Nothing is estimated.

## 5. Numeric columns are clean

- Every value in trans.amount, trans.balance, loan.amount, loan.duration, loan.payments and order.amount is a
  plain number (zero failures on a numeric pattern test), so conversion to numeric types cannot alter a value.
- Decision: convert to DECIMAL (amounts, balances, payments) and INT (duration) in staging.

## 6. Dates

- Dates are stored as YYMMDD text with no century. All values in account.date, loan.date, trans.date and
  card.issued (stored as YYMMDD followed by " 00:00:00") are well formed and real calendar dates.
- Observed ranges: accounts 1993-01-01 to 1997-12-29, loans 1993-07-05 to 1998-12-08, transactions
  1993-01-01 to 1998-12-31, cards 1993-11-07 to 1998-12-29. Every range sits inside 1993 to 1998, so a
  two-digit year of 93 to 98 maps to 1993 to 1998.
- No accounts were opened after 1997-12-29, so 1998 shows no new accounts.
- Decision: convert to DATE in staging; the constant " 00:00:00" time part on card.issued is dropped.

## 7. Date sequence

- 0 transactions, 0 loans and 0 cards are dated before their account was opened.
- Decision: no sequence problems.

## 8. Coded values

- Every coded column has a short, clean list of values with no typos or duplicate spellings, and each column's
  counts add up to its table's row count. Values: account.frequency (POPLATEK MESICNE 4,167, POPLATEK TYDNE 240,
  POPLATEK PO OBRATU 93), card.type (classic, junior, gold), disp.type (OWNER 4,500, DISPONENT 869),
  loan.status (A 203, B 31, C 403, D 45), trans.type (VYDAJ, PRIJEM, VYBER), trans.operation (five values plus
  blank) and the k_symbol codes in trans and order.
- Loan status: A and C (no problems) total 606 and B and D (not paid or in debt) total 76, matching the counts
  published for the dataset.
- trans.type has a third value, VYBER (16,666 rows), alongside PRIJEM and VYDAJ. These rows are cash
  withdrawals with no partner bank or account.
- The "no value" form of k_symbol appears in two ways: a true empty string and a single space. The single
  space occurs only in outgoing transfers (52,817 rows) and cash withdrawals (616 rows), and both forms span
  the whole period (1993 to 1998), so there is no evidence they differ in meaning.
- Decision: trim k_symbol, then treat both forms as NULL ("no payment purpose recorded").

## 9. Client birth numbers

- `birth_number` packs date of birth and gender into six digits (YYMMDD); for women 50 is added to the month.
- All 5,369 values are well formed and decode to real dates. The split is 2,645 female and 2,724 male
  (49.3% and 50.7%), which supports the month rule.
- The two-digit year has no century. Birth years decode as 19YY: the oldest client was born 1911-08-20, so no
  year falls in the 00 to 10 range that would be ambiguous.
- Decision: decode to `birth_date` and `gender` in staging and drop the raw field.
- Age: measured on 1998-12-31, 72 clients (1.3%) are under 18, of whom 57 are account owners and 15 are
  authorised users. Kept: the data has a junior card type, so minors holding accounts looks like a feature of
  the bank, not an error. Age-based analyses use age at the relevant date, not age at the end of the data.
- Each of the 4,500 accounts has exactly one OWNER disposition (4,500 owners, 869 other authorised users).

## 10. Amounts

- No amount is negative in any table: transaction amounts are positive, and the direction is held in `type`
  (PRIJEM credit, VYDAJ debit).
- Ranges: trans.amount 0 to 87,400; loan.amount 4,980 to 590,820; loan.payments 304 to 9,910; loan.duration
  12 to 60 months; order.amount 1 to 14,882. No zero or negative loan or order values.
- 14 transactions (0.001%) have an amount of exactly 0. All are interest postings: 10 penalty-interest debits
  (SANKC. UROK) and 4 interest credits (UROK). The cause is not stated in the data; rounding of a very small
  interest amount is a plausible explanation, not a confirmed one.
- Decision: keep all 14. They add nothing to any total. Analyses that count transactions filter on amount > 0.

## 11. Negative balances

- 2,999 transactions (0.28% of rows) show a negative balance, down to -41,125.70. They come from 288 of the
  4,500 accounts (6.4%), averaging 10.4 negative-balance transactions per overdrawn account, with a maximum of
  124 for one account.
- An overdrawn account is a legitimate state, not a data error.
- Decision: keep all rows; `balance` is stored as a signed decimal in staging.
