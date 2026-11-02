-- Plan mix: which tier carries the revenue, and what it costs to acquire it
-- in seats. Useful for pricing conversations.

with mrr as (

    select * from {{ ref('fct_mrr_monthly') }}
    where month_start = (select max(month_start) from {{ ref('fct_mrr_monthly') }})

)

select
    plan_name,
    count(distinct account_id)                          as accounts,
    sum(seats)                                          as seats,
    round(sum(mrr_usd), 2)                              as mrr_usd,
    {{ safe_divide('sum(mrr_usd)', 'count(distinct account_id)', 2) }} as mrr_per_account,
    {{ safe_divide('sum(mrr_usd) * 100', 'sum(sum(mrr_usd)) over ()', 2) }} as pct_of_total_mrr
from mrr
group by plan_name
order by mrr_usd desc
