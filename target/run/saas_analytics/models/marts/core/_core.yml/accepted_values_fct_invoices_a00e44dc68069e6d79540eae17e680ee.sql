
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        payment_speed as value_field,
        count(*) as n_records

    from (select * from "saas"."marts"."fct_invoices" where is_paid) dbt_subquery
    group by payment_speed

)

select *
from all_values
where value_field not in (
    'same day','0-7 days','8-30 days','30+ days'
)



  
  
      
    ) dbt_internal_test