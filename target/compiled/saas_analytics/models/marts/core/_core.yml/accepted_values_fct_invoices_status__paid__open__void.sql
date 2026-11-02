
    
    

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


