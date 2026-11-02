
    
    

select
    mrr_row_id as unique_field,
    count(*) as n_records

from "saas"."marts"."fct_mrr_monthly"
where mrr_row_id is not null
group by mrr_row_id
having count(*) > 1


