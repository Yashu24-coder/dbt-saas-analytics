
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    plan_name as unique_field,
    count(*) as n_records

from "saas"."marts"."mart_revenue_by_plan"
where plan_name is not null
group by plan_name
having count(*) > 1



  
  
      
    ) dbt_internal_test