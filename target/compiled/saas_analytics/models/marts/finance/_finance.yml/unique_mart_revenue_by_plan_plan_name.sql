
    
    

select
    plan_name as unique_field,
    count(*) as n_records

from "saas"."marts"."mart_revenue_by_plan"
where plan_name is not null
group by plan_name
having count(*) > 1


