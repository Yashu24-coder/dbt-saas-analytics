{{
    config(
        materialized='incremental',
        unique_key='mrr_row_id',
        incremental_strategy='delete+insert',
        on_schema_change='sync_all_columns'
    )
}}

-- Monthly recurring revenue at subscription-month grain. Incremental on
-- mrr_row_id, so re-running a month replaces it instead of double counting.

with subscription_months as (

    select * from {{ ref('int_subscription_months') }}
    {% if is_incremental() %}
    where month_start >= (select max(month_start) from {{ this }})
    {% endif %}

),

plans as (

    select * from {{ ref('stg_plans') }}

),

accounts as (

    select account_id, segment, country from {{ ref('dim_accounts') }}

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
    {{ cents_to_dollars('p.monthly_price_cents * sm.seats') }}  as mrr_usd,
    sm.is_first_month,
    sm.is_last_month,
    sm.status
from subscription_months sm
left join plans p using (plan_id)
left join accounts a using (account_id)
where p.monthly_price_cents is not null
