-- MRR is plan price x seats. Neither can be negative, so a negative MRR row
-- means the seats join or the price cast has broken.

select
    mrr_row_id,
    mrr_cents
from {{ ref('fct_mrr_monthly') }}
where mrr_cents <= 0
