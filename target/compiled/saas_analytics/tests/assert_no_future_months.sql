-- The month spine must stop at the analysis end month, otherwise the pipeline
-- quietly invents revenue for months that have not happened.

select
    month_start
from "saas"."marts"."fct_mrr_monthly"
where month_start > date '2026-10-01'