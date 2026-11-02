
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month_start
from "saas"."marts"."fct_mrr_monthly"
where month_start is null



  
  
      
    ) dbt_internal_test