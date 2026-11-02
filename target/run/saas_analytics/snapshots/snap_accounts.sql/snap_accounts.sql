
      
    

    create  table
      "saas"."snapshots"."snap_accounts"
  
    
    as (
      
    

    select *,
        md5(coalesce(cast(account_id as varchar ), '')
         || '|' || coalesce(cast(now()::timestamp as varchar ), '')
        ) as dbt_scd_id,
        now()::timestamp as dbt_updated_at,
        now()::timestamp as dbt_valid_from,
        
  
  coalesce(nullif(now()::timestamp, now()::timestamp), null)
  as dbt_valid_to
from (
        



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

    ) sbq



    );
    
  
  