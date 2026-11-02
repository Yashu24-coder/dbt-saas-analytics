
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  -- An account should never be billed on two overlapping subscriptions in the
-- same month - that is a double-billing bug, not a data quirk.

select
    month_start,
    account_id,
    count(*) as active_subscriptions
from "saas"."marts"."fct_mrr_monthly"
group by month_start, account_id
having count(*) > 1
  
  
      
    ) dbt_internal_test