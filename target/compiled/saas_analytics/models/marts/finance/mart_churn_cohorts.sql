-- Cohort retention: of the accounts that started in month X, how many are still
-- paying N months later. The classic "is the leak getting worse" chart.

with accounts as (

    select account_id, cohort_month from "saas"."marts"."dim_accounts"

),

active as (

    select distinct
        account_id,
        month_start
    from "saas"."marts"."fct_mrr_monthly"
    where mrr_cents > 0

),

cohort_sizes as (

    select cohort_month, count(*) as cohort_accounts
    from accounts
    group by cohort_month

),

retention as (

    select
        a.cohort_month,
        date_diff('month', a.cohort_month, ac.month_start) as months_since_start,
        count(distinct a.account_id)                       as retained_accounts
    from accounts a
    inner join active ac using (account_id)
    group by a.cohort_month, months_since_start

)

select
    r.cohort_month,
    r.months_since_start,
    c.cohort_accounts,
    r.retained_accounts,
    
    round(
        (r.retained_accounts * 100)::decimal(18, 6) / nullif(c.cohort_accounts, 0),
        2
    )
 as retention_pct
from retention r
inner join cohort_sizes c using (cohort_month)
where r.months_since_start between 0 and 11
order by r.cohort_month, r.months_since_start