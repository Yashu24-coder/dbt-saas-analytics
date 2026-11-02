-- Plan mix: which tier carries the revenue, and what it costs to acquire it
-- in seats. Useful for pricing conversations.

with mrr as (

    select * from "saas"."marts"."fct_mrr_monthly"
    where month_start = (select max(month_start) from "saas"."marts"."fct_mrr_monthly")

)

select
    plan_name,
    count(distinct account_id)                          as accounts,
    sum(seats)                                          as seats,
    round(sum(mrr_usd), 2)                              as mrr_usd,
    
    round(
        (sum(mrr_usd))::decimal(18, 6) / nullif(count(distinct account_id), 0),
        2
    )
 as mrr_per_account,
    
    round(
        (sum(mrr_usd) * 100)::decimal(18, 6) / nullif(sum(sum(mrr_usd)) over (), 0),
        2
    )
 as pct_of_total_mrr
from mrr
group by plan_name
order by mrr_usd desc