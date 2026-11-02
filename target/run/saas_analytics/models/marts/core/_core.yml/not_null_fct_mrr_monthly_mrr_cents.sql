
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mrr_cents
from "saas"."marts"."fct_mrr_monthly"
where mrr_cents is null



  
  
      
    ) dbt_internal_test