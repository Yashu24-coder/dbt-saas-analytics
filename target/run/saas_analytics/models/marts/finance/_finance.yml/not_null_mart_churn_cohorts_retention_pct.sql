
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select retention_pct
from "saas"."marts"."mart_churn_cohorts"
where retention_pct is null



  
  
      
    ) dbt_internal_test