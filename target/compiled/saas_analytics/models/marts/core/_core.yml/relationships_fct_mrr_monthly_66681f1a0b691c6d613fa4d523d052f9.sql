
    
    

with child as (
    select subscription_id as from_field
    from "saas"."marts"."fct_mrr_monthly"
    where subscription_id is not null
),

parent as (
    select subscription_id as to_field
    from "saas"."staging"."stg_subscriptions"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


