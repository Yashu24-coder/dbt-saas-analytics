-- Successful payments against invoices.

with source as (

    select * from {{ source('raw', 'payments') }}

),

renamed as (

    select
        trim(payment_id)                        as payment_id,
        trim(invoice_id)                        as invoice_id,
        coalesce(
            try_strptime(trim(paid_at), '%Y-%m-%d'),
            try_strptime(trim(paid_at), '%d/%m/%Y')
        )::date                                 as paid_at,
        cast(
            replace(replace(trim(amount_cents), '.', ''), ',', '.') as double
        )                                       as amount_cents,
        lower(trim(method))                     as method
    from source
    where payment_id is not null

)

select * from renamed
