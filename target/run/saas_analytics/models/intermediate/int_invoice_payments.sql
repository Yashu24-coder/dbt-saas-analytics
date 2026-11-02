
  
  create view "saas"."intermediate"."int_invoice_payments__dbt_tmp" as (
    -- Invoices joined to their payments, with days-to-pay and a paid flag.

with invoices as (

    select * from "saas"."staging"."stg_invoices"

),

payments as (

    select
        invoice_id,
        sum(amount_cents)   as paid_cents,
        min(paid_at)        as first_paid_at,
        count(*)            as payment_count
    from "saas"."staging"."stg_payments"
    group by invoice_id

),

joined as (

    select
        i.invoice_id,
        i.account_id,
        i.subscription_id,
        i.invoice_date,
        i.amount_cents,
        i.amount_usd,
        i.status,
        i.is_credit_note,
        coalesce(p.paid_cents, 0)                       as paid_cents,
        p.first_paid_at,
        coalesce(p.payment_count, 0)                    as payment_count,
        date_diff('day', i.invoice_date, p.first_paid_at) as days_to_pay,
        i.status = 'paid' and coalesce(p.paid_cents, 0) > 0 as is_paid
    from invoices i
    left join payments p using (invoice_id)

)

select * from joined
  );
