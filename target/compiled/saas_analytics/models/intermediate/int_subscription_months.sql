-- One row per subscription per calendar month it was active. This is the spine
-- every MRR metric is built on: if a subscription covers five months, it appears
-- five times with one twelfth of nothing - the full monthly price each time.

with months as (

    select unnest(
        generate_series(
            (select date_trunc('month', min(started_at)) from "saas"."staging"."stg_subscriptions"),
            (select date_trunc('month', max(active_until)) from "saas"."staging"."stg_subscriptions"),
            interval 1 month
        )
    )::date as month_start

),

subscriptions as (

    select * from "saas"."staging"."stg_subscriptions"

),

expanded as (

    select
        s.subscription_id,
        s.account_id,
        s.plan_id,
        s.seats,
        s.status,
        s.started_at,
        s.ended_at,
        m.month_start,
        m.month_start = date_trunc('month', s.started_at)::date  as is_first_month,
        m.month_start = date_trunc('month', s.active_until)::date as is_last_month
    from subscriptions s
    inner join months m
        on m.month_start >= date_trunc('month', s.started_at)::date
       and m.month_start <= date_trunc('month', s.active_until)::date

)

select * from expanded