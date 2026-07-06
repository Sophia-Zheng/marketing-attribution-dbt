-- Wide comparison table: one row per channel, one column per attribution model.
-- This is the table a dashboard sits on.
with base as (
    select * from {{ ref('attribution_by_model') }}
)

select
    channel,
    max(case when attribution_model = 'first_click'    then credited_revenue end) as first_click_revenue,
    max(case when attribution_model = 'last_click'     then credited_revenue end) as last_click_revenue,
    max(case when attribution_model = 'linear'         then credited_revenue end) as linear_revenue,
    max(case when attribution_model = 'position_based' then credited_revenue end) as position_based_revenue
from base
group by channel
order by linear_revenue desc nulls last
