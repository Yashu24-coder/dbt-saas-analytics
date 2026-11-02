
    

    create  table
      "saas"."marts"."dim_accounts__dbt_tmp"
  
    
    as (
      -- Account dimension. Segment and industry come from the account record; the
-- current plan and MRR come from the latest active subscription.

with accounts as (

    select * from "saas"."staging"."stg_accounts"

),

latest_subscription as (

    select
        account_id,
        plan_id,
        seats,
        started_at,
        ended_at,
        status
    from "saas"."staging"."stg_subscriptions"
    qualify row_number() over (partition by account_id order by started_at desc) = 1

),

plans as (

    select * from "saas"."staging"."stg_plans"

)

select
    a.account_id,
    a.account_name,
    a.country,
    a.industry,
    a.segment,
    a.created_at,
    date_trunc('month', a.created_at)::date             as cohort_month,
    l.plan_id                                           as current_plan_id,
    p.plan_name                                         as current_plan_name,
    l.seats                                             as current_seats,
    l.status                                            as current_status,
    l.started_at                                        as current_plan_started_at,
    
    round((p.monthly_price_cents * l.seats) / 100.0, 2)
 as current_mrr_usd
from accounts a
left join latest_subscription l using (account_id)
left join plans p using (plan_id)
    );
    
  