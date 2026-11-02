-- Every invoice marked paid must have a payment row covering at least 99% of
-- its amount (1% tolerance for rounding in the source export).

select
    invoice_id,
    amount_cents,
    paid_cents
from "saas"."marts"."fct_invoices"
where status = 'paid'
  and abs(paid_cents - amount_cents) > abs(amount_cents) * 0.01