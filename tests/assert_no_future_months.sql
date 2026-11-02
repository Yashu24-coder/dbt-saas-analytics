-- The month spine must stop at the analysis end month, otherwise the pipeline
-- quietly invents revenue for months that have not happened.

select
    month_start
from {{ ref('fct_mrr_monthly') }}
where month_start > date '{{ var("analysis_end_month") }}'
