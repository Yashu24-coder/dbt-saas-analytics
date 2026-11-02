# Model reference

Schemas are fixed by `macros/generate_schema_name.sql`, so a local run and a CI
run produce identical names: `raw` (external CSV sources), `staging`,
`intermediate`, `marts`, `snapshots`.

## Sources - `raw`

Read directly from `data/raw/*.csv` through dbt-duckdb `external_location`, with
`all_varchar = true`. Every column arrives as text because the exports are text.

| Source | Rows | Notes |
|---|---|---|
| `plans` | 4 | Plan SKUs with a monthly price in cents |
| `accounts` | 180 | One row per customer account |
| `subscriptions` | 207 | One row per subscription period; upgrades end one and start another |
| `invoices` | 2,338 | Includes 40 duplicate rows and void credit notes |
| `payments` | 2,118 | One row per successful payment |

## staging

| Model | Grain | Key transforms |
|---|---|---|
| `stg_plans` | plan | `monthly_price_cents` cast to integer, `plan_name` title-cased, dollars derived with `cents_to_dollars` |
| `stg_accounts` | account | `coalesce(try_strptime('%Y-%m-%d'), try_strptime('%d/%m/%Y'))`, country and industry normalised, deduplicated on `account_id` |
| `stg_subscriptions` | subscription | Both dates parsed, `ended_at` null for active, `active_until` fills open periods with the analysis end month, `seats > 0` filter |
| `stg_invoices` | invoice | Thousand separators stripped, `status` lower-cased, duplicates collapsed on `invoice_id`, `is_credit_note` flag |
| `stg_payments` | payment | Amounts and dates typed |

## intermediate

**`int_subscription_months`** - one row per subscription per calendar month it
was active. Columns: `subscription_id`, `account_id`, `plan_id`, `seats`,
`status`, `started_at`, `ended_at`, `month_start`, `is_first_month`,
`is_last_month`. This is the only place the month spine is generated.

**`int_invoice_payments`** - one row per invoice. Columns: `invoice_id`,
`account_id`, `subscription_id`, `invoice_date`, `amount_cents`, `amount_usd`,
`status`, `is_credit_note`, `paid_cents`, `first_paid_at`, `payment_count`,
`days_to_pay`, `is_paid`.

## marts

| Model | Grain | Columns |
|---|---|---|
| `dim_accounts` | account | `account_id`, `account_name`, `country`, `industry`, `segment`, `created_at`, `cohort_month`, `current_plan_id`, `current_plan_name`, `current_seats`, `current_status`, `current_plan_started_at`, `current_mrr_usd` |
| `fct_mrr_monthly` | subscription-month | `mrr_row_id`, `month_start`, `subscription_id`, `account_id`, `plan_id`, `plan_name`, `segment`, `country`, `seats`, `monthly_price_cents`, `mrr_cents`, `mrr_usd`, `is_first_month`, `is_last_month`, `status` |
| `fct_invoices` | invoice | `invoice_id`, `account_id`, `subscription_id`, `invoice_date`, `invoice_month`, `amount_cents`, `amount_usd`, `status`, `is_credit_note`, `paid_cents`, `first_paid_at`, `days_to_pay`, `is_paid`, `payment_speed` |
| `mart_mrr_summary` | month | `month_start`, `mrr_usd`, `previous_mrr_usd`, `net_new_mrr_usd`, `new_mrr_usd`, `churned_mrr_usd`, `paying_accounts`, `arpu_usd`, `arr_usd`, `mom_growth_rate` |
| `mart_churn_cohorts` | cohort-month | `cohort_month`, `months_since_start`, `cohort_accounts`, `retained_accounts`, `retention_pct` |
| `mart_revenue_by_plan` | plan | `plan_name`, `accounts`, `seats`, `mrr_usd`, `mrr_per_account`, `pct_of_total_mrr` |

## Snapshots

`snap_accounts` (schema `snapshots`) is a check-strategy type-2 history on
`current_plan_name`, `segment` and `current_seats`. Columns added by dbt:
`dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`.
