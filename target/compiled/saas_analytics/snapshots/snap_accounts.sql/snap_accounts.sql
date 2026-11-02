



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
from "saas"."marts"."dim_accounts"
