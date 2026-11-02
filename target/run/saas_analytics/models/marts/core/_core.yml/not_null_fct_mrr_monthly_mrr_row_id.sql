
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mrr_row_id
from "saas"."marts"."fct_mrr_monthly"
where mrr_row_id is null



  
  
      
    ) dbt_internal_test