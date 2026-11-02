{% snapshot snap_accounts %}

{{
    config(
        target_schema='snapshots',
        unique_key='account_id',
        strategy='check',
        check_cols=['current_plan_name', 'segment', 'current_seats'],
    )
}}

-- Slowly changing dimension type 2 on the account's plan and seats. Running
-- dbt build again after a plan change adds a new version rather than
-- overwriting history, which is how you answer "what were they paying in March".

select
    account_id,
    account_name,
    segment,
    current_plan_name,
    current_seats,
    current_mrr_usd
from {{ ref('dim_accounts') }}

{% endsnapshot %}
