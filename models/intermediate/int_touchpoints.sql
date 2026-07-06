-- All marketing touchpoints (session starts), ordered per user.
select
    event_id,
    user_pseudo_id,
    event_ts   as touch_ts,
    channel,
    source,
    medium,
    campaign,
    row_number() over (partition by user_pseudo_id order by event_ts) as touch_number
from {{ ref('stg_events') }}
where event_name = 'session_start'
