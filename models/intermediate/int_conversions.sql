-- Purchases (first conversion per user, to keep journeys unambiguous).
with purchases as (
    select
        user_pseudo_id,
        event_ts as conversion_ts,
        coalesce(revenue, 0) as revenue,
        row_number() over (partition by user_pseudo_id order by event_ts) as rn
    from {{ ref('stg_events') }}
    where event_name = 'purchase'
)
select user_pseudo_id, conversion_ts, revenue
from purchases
where rn = 1
