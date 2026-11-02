
    

    create  table
      "saas"."marts"."fct_invoices__dbt_tmp"
  
    
    as (
      -- Invoice fact: one row per invoice, with payment behaviour attached.
-- Credit notes stay in the table but are excluded from revenue by the marts.

select
    invoice_id,
    account_id,
    subscription_id,
    invoice_date,
    date_trunc('month', invoice_date)::date     as invoice_month,
    amount_cents,
    amount_usd,
    status,
    is_credit_note,
    paid_cents,
    first_paid_at,
    days_to_pay,
    is_paid,
    case
        when days_to_pay is null then null
        when days_to_pay <= 0 then 'same day'
        when days_to_pay <= 7 then '0-7 days'
        when days_to_pay <= 30 then '8-30 days'
        else '30+ days'
    end                                          as payment_speed
from "saas"."intermediate"."int_invoice_payments"
    );
    
  