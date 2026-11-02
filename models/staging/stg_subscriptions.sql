-- Subscription periods. An account that upgrades has two rows: the first ends
-- on the upgrade date, the second starts on it.

with source as (

    select * from {{ source('raw', 'subscriptions') }}

),

renamed as (

    select
        trim(subscription_id)                   as subscription_id,
        trim(account_id)                        as account_id,
        trim(plan_id)                           as plan_id,
        coalesce(
            try_strptime(trim(started_at), '%Y-%m-%d'),
            try_strptime(trim(started_at), '%d/%m/%Y')
        )::date                                 as started_at,
        coalesce(
            try_strptime(nullif(trim(ended_at), ''), '%Y-%m-%d'),
            try_strptime(nullif(trim(ended_at), ''), '%d/%m/%Y')
        )::date                                 as ended_at,
        lower(trim(status))                     as status,
        cast(seats as integer)                  as seats
    from source
    where subscription_id is not null

),

cleaned as (

    select
        *,
        coalesce(ended_at, date '{{ var("analysis_end_month") }}') as active_until
    from renamed
    where started_at is not null
      and cast(seats as integer) > 0

)

select * from cleaned
