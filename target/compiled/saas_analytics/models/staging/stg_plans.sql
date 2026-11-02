-- Plan SKUs with a typed monthly price.

with source as (

    select * from read_csv_auto('data/raw/plans.csv', all_varchar = true)

),

renamed as (

    select
        plan_id,
        upper(substr(trim(plan_name), 1, 1)) || lower(substr(trim(plan_name), 2))
                 as plan_name,
        cast(monthly_price_cents as integer)     as monthly_price_cents,
        
    round((cast(monthly_price_cents as integer)) / 100.0, 2)
 as monthly_price_usd,
        lower(trim(billing_interval))            as billing_interval
    from source
    where plan_id is not null

)

select * from renamed