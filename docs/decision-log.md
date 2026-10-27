# Decision log: Bank Dataset cleaning

Every cleaning decision in this project, with the evidence that led to it. Nothing is removed
silently, and every count below can be reproduced with the scripts in `sql/`.

## 1. IDs are not unique: the files are three stacked batches

**Finding.** Every ID column appears exactly three times in its table:

| Table | Rows | Distinct IDs | Rows per batch |
|---|---|---|---|
| account | 3,000 | 1,000 | 1,000 |
| customer | 3,000 | 1,000 | 1,000 |
| branch | 150 | 50 | 50 |
| loan | 1,500 | 500 | 500 |
| transaction | 15,000 | 5,000 | 5,000 |

**Evidence that these are different records, not copies.** The three rows with `CUSTOMER_ID = C00001` are
three different people (different names, cities, phone numbers, occupations and dates of birth).

**Evidence for the batch layout.** In every file, the ID restarts at 00001 exactly at the batch boundary
(lines 2, 1002 and 2002 of the customer file, for example) and ends at the last ID of the batch
(C01000, B00050, L00500, T05000) on the last line of each batch.

**Decision.**
- Do not remove any rows: they are not duplicates.
- The raw tables carry a `row_no` column (the row's position in its file), because a SQL table has no
  inherent row order. A row's batch is derived from `row_no`.
- The real key of each table is (batch, ID), not the ID alone.

**Assumption (cannot be tested).** Batch n of one table is linked to batch n of the others (for example,
accounts in batch 2 belong to customers in batch 2). Loans and transactions reference customer and account IDs
that exist in all three batches, so nothing in the data confirms which batch a reference points to.
Results that join across tables depend on this assumption.
