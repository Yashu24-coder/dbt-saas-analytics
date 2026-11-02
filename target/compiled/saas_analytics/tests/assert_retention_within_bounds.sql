-- Retention is a percentage of a cohort, so it must sit between 0 and 100.

select
    cohort_month,
    months_since_start,
    retention_pct
from "saas"."marts"."mart_churn_cohorts"
where retention_pct < 0 or retention_pct > 100