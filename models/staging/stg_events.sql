with raw as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_timestamp', 'event_name']) }} as event_id,
        user_pseudo_id,
        timestamp_micros(event_timestamp)  as event_timestamp,
        event_name,
        traffic_source.source              as source,
        traffic_source.medium              as medium,
        traffic_source.name                as campaign,
        ecommerce.purchase_revenue         as revenue
    from {{ source('ga4', 'events') }}
    where _table_suffix between '20210101' and '20210131'
),

cleaned as (
    select
        event_id,
        user_pseudo_id,
        cast(event_timestamp as timestamp)          as event_ts,
        lower(event_name)                           as event_name,
        lower(source)                               as source,
        lower(medium)                               as medium,
        lower(campaign)                             as campaign,
        cast(nullif(cast(revenue as string), '') as numeric) as revenue,

        -- GA-style default channel grouping
        case
            when medium = 'cpc'                         then 'Paid Search'
            when medium = 'paid_social'                 then 'Paid Social'
            when medium = 'email'                       then 'Email'
            when medium = 'organic'                     then 'Organic Search'
            when medium = 'referral'                    then 'Referral'
            when source = '(direct)'                    then 'Direct'
            else 'Other'
        end                                          as channel
    from raw
    qualify row_number() over (partition by event_id order by event_timestamp) = 1
)

select * from cleaned