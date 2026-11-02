
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select plan_name
from "saas"."marts"."mart_revenue_by_plan"
where plan_name is null



  
  
      
    ) dbt_internal_test