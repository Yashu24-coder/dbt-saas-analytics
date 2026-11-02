# Runbook

## Daily / on every change

```bash
dbt build --profiles-dir .
```

Green means: every model built, all 27 tests passed. A red build is the point of
the project - do not publish a number the tests rejected.

## Re-running a month

`fct_mrr_monthly` is incremental on `mrr_row_id` (a hash of subscription and
month), so a re-run replaces the affected months rather than duplicating them:

```bash
dbt run --select fct_mrr_monthly+ --profiles-dir .
```

A full rebuild, when a staging definition changed:

```bash
dbt build --full-refresh --profiles-dir .
```

## Adding a source column

1. Add it to `data/raw` (and to `scripts/generate_seeds.py` if it is synthetic).
2. Add it to `models/staging/_sources.yml` with a description.
3. Type it in the relevant `stg_` model. Never let a raw string reach a mart.
4. Add a `not_null` or `accepted_values` test if it is a key or an enum.
5. `dbt build` and update `docs/model_reference.md`.

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| `Catalog Error: Table ... does not exist` | raw CSVs missing | `python scripts/generate_seeds.py` |
| `assert_one_active_subscription_per_account_month` fails | an upgrade was recorded mid-month, so two subscriptions cover one month | move the switch to a month boundary upstream, or exclude the upgrade month in the model and document it |
| `assert_paid_invoices_have_payments` fails | an invoice is marked paid with no payment row | check the payments export for the missing period |
| `dbt build` hangs or errors on the DuckDB file | a second process has the warehouse open | close the other session, or `rm data/warehouse/saas.duckdb` and rebuild |
| `retention_pct` above 100 | cohort size counted after filtering instead of before | rebuild `cohort_sizes` from `dim_accounts`, not from the filtered join |

## Where the numbers live

`reports/stats.json` is written by `scripts/render_assets.py` from the warehouse
that the last build produced. Every figure in the README comes from that file,
so re-running the pipeline and the script keeps the docs honest.
