-- Stitch each conversion to the touchpoints that preceded it
-- within the lookback window, ranked from first to last touch.
with joined as (
    select
        c.user_pseudo_id,
        c.conversion_ts,
        c.revenue,
        t.touch_ts,
        t.channel,
        t.campaign
    from {{ ref('int_conversions') }} c
    join {{ ref('int_touchpoints') }} t
      on t.user_pseudo_id = c.user_pseudo_id
     and t.touch_ts <= c.conversion_ts
     and t.touch_ts >= timestamp_sub(c.conversion_ts, interval {{ var("lookback_days") }} day)
)

select
    *,
    row_number() over (partition by user_pseudo_id order by touch_ts)        as path_position,
    count(*)    over (partition by user_pseudo_id)                           as path_length
from joined
