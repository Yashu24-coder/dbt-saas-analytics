

-- Monthly recurring revenue at subscription-month grain. Incremental on
-- mrr_row_id, so re-running a month replaces it instead of double counting.

with subscription_months as (

    select * from "saas"."intermediate"."int_subscription_months"
    

),

plans as (

    select * from "saas"."staging"."stg_plans"

),

accounts as (

    select account_id, segment, country from "saas"."marts"."dim_accounts"

)

select
    md5(sm.subscription_id || '|' || cast(sm.month_start as varchar)) as mrr_row_id,
    sm.month_start,
    sm.subscription_id,
    sm.account_id,
    sm.plan_id,
    p.plan_name,
    a.segment,
    a.country,
    sm.seats,
    p.monthly_price_cents,
    p.monthly_price_cents * sm.seats                            as mrr_cents,
    
    round((p.monthly_price_cents * sm.seats) / 100.0, 2)
  as mrr_usd,
    sm.is_first_month,
    sm.is_last_month,
    sm.status
from subscription_months sm
left join plans p using (plan_id)
left join accounts a using (account_id)
where p.monthly_price_cents is not null