
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "saas"."marts"."fct_invoices"
    group by status

)

select *
from all_values
where value_field not in (
    'paid','open','void'
)



  
  
      
    ) dbt_internal_test