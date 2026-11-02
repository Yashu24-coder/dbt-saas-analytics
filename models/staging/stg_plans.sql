-- Plan SKUs with a typed monthly price.

with source as (

    select * from {{ source('raw', 'plans') }}

),

renamed as (

    select
        plan_id,
        {{ title_case('plan_name') }}                 as plan_name,
        cast(monthly_price_cents as integer)     as monthly_price_cents,
        {{ cents_to_dollars('cast(monthly_price_cents as integer)') }} as monthly_price_usd,
        lower(trim(billing_interval))            as billing_interval
    from source
    where plan_id is not null

)

select * from renamed
