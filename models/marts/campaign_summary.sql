with paths as (
    select * from {{ ref('int_conversion_paths') }}
)

select
    channel,
    campaign,
    round(sum(1.0 / path_length), 2)      as credited_conversions,
    round(sum(revenue / path_length), 2)  as credited_revenue
from paths
group by campaign, channel
order by credited_revenue desc