-- Monthly MRR movement: the number a founder asks for first.
-- new = subscriptions starting this month, churned = subscriptions ending this
-- month, net new = movement between this month and the previous one.

with monthly as (

    select
        month_start,
        sum(mrr_usd)                                    as mrr_usd,
        count(distinct account_id)                      as paying_accounts,
        sum(case when is_first_month then mrr_usd else 0 end)  as new_mrr_usd,
        sum(case when is_last_month and status = 'churned' then mrr_usd else 0 end) as churned_mrr_usd
    from "saas"."marts"."fct_mrr_monthly"
    group by month_start

),

with_previous as (

    select
        *,
        lag(mrr_usd) over (order by month_start) as previous_mrr_usd
    from monthly

)

select
    month_start,
    mrr_usd,
    previous_mrr_usd,
    round(mrr_usd - coalesce(previous_mrr_usd, 0), 2)      as net_new_mrr_usd,
    new_mrr_usd,
    churned_mrr_usd,
    paying_accounts,
    
    round(
        (mrr_usd)::decimal(18, 6) / nullif(paying_accounts, 0),
        2
    )
     as arpu_usd,
    
    round(
        (mrr_usd * 12)::decimal(18, 6) / nullif(1, 0),
        2
    )
              as arr_usd,
    
    round(
        (mrr_usd - coalesce(previous_mrr_usd, 0))::decimal(18, 6) / nullif(previous_mrr_usd, 0),
        4
    )
 as mom_growth_rate
from with_previous
order by month_start