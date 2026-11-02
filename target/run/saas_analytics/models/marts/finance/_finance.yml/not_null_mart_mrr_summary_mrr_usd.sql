
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mrr_usd
from "saas"."marts"."mart_mrr_summary"
where mrr_usd is null



  
  
      
    ) dbt_internal_test