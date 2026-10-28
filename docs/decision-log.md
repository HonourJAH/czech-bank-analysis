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
