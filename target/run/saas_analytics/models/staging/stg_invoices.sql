
  
  create view "saas"."staging"."stg_invoices__dbt_tmp" as (
    -- Invoices, with the duplicate rows from the re-run billing job collapsed.
-- Void credit notes are kept but flagged, so they never count as revenue.

with source as (

    select * from read_csv_auto('data/raw/invoices.csv', all_varchar = true)

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
    
    round((amount_cents) / 100.0, 2)
          as amount_usd
from deduplicated
  );
