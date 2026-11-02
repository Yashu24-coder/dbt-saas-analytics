-- Accounts with a parsed created_at and a normalised country label.

with source as (

    select * from {{ source('raw', 'accounts') }}

),

renamed as (

    select
        trim(account_id)                        as account_id,
        trim(account_name)                      as account_name,
        case upper(trim(country))
            when 'UAE' then 'United Arab Emirates'
            when 'UNITED STATES' then 'United States'
            when 'UNITED KINGDOM' then 'United Kingdom'
            else {{ title_case('country') }}
        end                                     as country,
        {{ title_case('industry') }}                 as industry,
        lower(trim(segment))                    as segment,
        coalesce(
            try_strptime(trim(created_at), '%Y-%m-%d'),
            try_strptime(trim(created_at), '%d/%m/%Y')
        )::date                                 as created_at
    from source
    where account_id is not null

),

deduplicated as (

    select *
    from renamed
    qualify row_number() over (partition by account_id order by created_at) = 1

)

select * from deduplicated
