
    
    

select
    month_start as unique_field,
    count(*) as n_records

from "saas"."marts"."mart_mrr_summary"
where month_start is not null
group by month_start
having count(*) > 1


