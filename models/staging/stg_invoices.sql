-- Invoices, with the duplicate rows from the re-run billing job collapsed.
-- Void credit notes are kept but flagged, so they never count as revenue.

with source as (

    select * from {{ source('raw', 'invoices') }}

),

renamed as (

    select
        trim(invoice_id)                        as invoice_id,
        trim(account_id)                        as account_id,
        trim(subscription_id)                   as subscription_id,
        coalesce(
            try_strptime(trim(invoice_date), '%Y-%m-%d'),
            try_strptime(trim(invoice_date), '%d/%m/%Y')
        )::date                                 as invoice_date,
        cast(
            replace(replace(trim(amount_cents), '.', ''), ',', '.') as double
        )                                       as amount_cents,
        upper(trim(currency))                   as currency,
        lower(trim(status))                     as status
    from source
    where invoice_id is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (partition by invoice_id order by invoice_date) = 1

)

select
    *,
    amount_cents < 0                                as is_credit_note,
    {{ cents_to_dollars('amount_cents') }}          as amount_usd
from deduplicated
