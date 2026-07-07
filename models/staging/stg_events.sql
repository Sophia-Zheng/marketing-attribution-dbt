-- Staging: clean + type raw GA4-style events, derive a channel grouping.
with raw as (
    select * from {{ ref('raw_events') }}
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
)

select * from cleaned
