
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    mrr_row_id as unique_field,
    count(*) as n_records

from "saas"."marts"."fct_mrr_monthly"
where mrr_row_id is not null
group by mrr_row_id
having count(*) > 1



  
  
      
    ) dbt_internal_test